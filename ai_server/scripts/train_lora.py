"""
LoRA Fine-tuning Script for Eyebrow Synthesis

This script trains a LoRA adapter on eyebrow images to improve
synthesis quality for specific eyebrow styles.

Usage:
    python scripts/train_lora.py --data_dir ./training_data --output_dir ./models/lora/eyebrow_v1
"""
import os
import argparse
import json
from pathlib import Path
from typing import Optional

import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
from accelerate import Accelerator
from diffusers import (
    AutoencoderKL,
    DDPMScheduler,
    UNet2DConditionModel,
)
from transformers import CLIPTextModel, CLIPTokenizer
from peft import LoraConfig, get_peft_model
from tqdm import tqdm


class EyebrowDataset(Dataset):
    """Dataset for eyebrow LoRA training"""

    def __init__(
        self,
        data_dir: str,
        tokenizer: CLIPTokenizer,
        size: int = 512,
        center_crop: bool = True
    ):
        self.data_dir = Path(data_dir)
        self.tokenizer = tokenizer
        self.size = size
        self.center_crop = center_crop

        # Find all images
        self.images_dir = self.data_dir / "images"
        self.captions_dir = self.data_dir / "captions"

        self.samples = []
        for img_path in self.images_dir.glob("*"):
            if img_path.suffix.lower() not in ['.png', '.jpg', '.jpeg', '.webp']:
                continue

            # Find matching caption
            caption_path = self.captions_dir / f"{img_path.stem}.txt"

            if caption_path.exists():
                caption = caption_path.read_text().strip()
            else:
                # Default caption with trigger word
                caption = "ohwx_eyebrow, realistic eyebrow, natural skin texture, high quality"

            self.samples.append({
                "image_path": img_path,
                "caption": caption
            })

        print(f"Loaded {len(self.samples)} training samples")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]

        # Load image
        image = Image.open(sample["image_path"]).convert("RGB")

        # Resize/crop
        if self.center_crop:
            image = self._center_crop_resize(image, self.size)
        else:
            image = image.resize((self.size, self.size), Image.LANCZOS)

        # Convert to tensor
        image = torch.tensor(list(image.getdata())).view(self.size, self.size, 3)
        image = image.permute(2, 0, 1).float() / 127.5 - 1.0  # [-1, 1]

        # Tokenize caption
        text_inputs = self.tokenizer(
            sample["caption"],
            padding="max_length",
            max_length=self.tokenizer.model_max_length,
            truncation=True,
            return_tensors="pt"
        )

        return {
            "pixel_values": image,
            "input_ids": text_inputs.input_ids.squeeze()
        }

    def _center_crop_resize(self, image: Image.Image, size: int) -> Image.Image:
        """Center crop then resize"""
        w, h = image.size
        min_dim = min(w, h)

        left = (w - min_dim) // 2
        top = (h - min_dim) // 2

        image = image.crop((left, top, left + min_dim, top + min_dim))
        image = image.resize((size, size), Image.LANCZOS)

        return image


class LoRATrainer:
    """LoRA training manager"""

    def __init__(
        self,
        model_name: str = "runwayml/stable-diffusion-v1-5",
        output_dir: str = "models/lora/eyebrow_v1",
        lora_rank: int = 32,
        lora_alpha: int = 32,
        learning_rate: float = 1e-4,
        gradient_accumulation_steps: int = 4
    ):
        self.model_name = model_name
        self.output_dir = Path(output_dir)
        self.lora_rank = lora_rank
        self.lora_alpha = lora_alpha
        self.learning_rate = learning_rate

        self.accelerator = Accelerator(
            gradient_accumulation_steps=gradient_accumulation_steps,
            mixed_precision="fp16"
        )

        self._load_models()

    def _load_models(self):
        """Load base models"""
        print("Loading base models...")

        # Tokenizer
        self.tokenizer = CLIPTokenizer.from_pretrained(
            self.model_name,
            subfolder="tokenizer"
        )

        # Text encoder (frozen)
        self.text_encoder = CLIPTextModel.from_pretrained(
            self.model_name,
            subfolder="text_encoder"
        )
        self.text_encoder.requires_grad_(False)

        # VAE (frozen)
        self.vae = AutoencoderKL.from_pretrained(
            self.model_name,
            subfolder="vae"
        )
        self.vae.requires_grad_(False)

        # UNet (will add LoRA)
        self.unet = UNet2DConditionModel.from_pretrained(
            self.model_name,
            subfolder="unet"
        )

        # Noise scheduler
        self.noise_scheduler = DDPMScheduler.from_pretrained(
            self.model_name,
            subfolder="scheduler"
        )

        # Apply LoRA
        self._setup_lora()

    def _setup_lora(self):
        """Configure LoRA adapters"""
        lora_config = LoraConfig(
            r=self.lora_rank,
            lora_alpha=self.lora_alpha,
            init_lora_weights="gaussian",
            target_modules=[
                "to_k",
                "to_q",
                "to_v",
                "to_out.0",
                "add_k_proj",
                "add_v_proj",
            ],
        )

        self.unet = get_peft_model(self.unet, lora_config)

        # Print trainable parameters
        trainable, total = 0, 0
        for param in self.unet.parameters():
            total += param.numel()
            if param.requires_grad:
                trainable += param.numel()

        print(f"Trainable parameters: {trainable:,} / {total:,} ({100*trainable/total:.2f}%)")

    def train(
        self,
        data_dir: str,
        num_epochs: int = 100,
        batch_size: int = 1,
        save_every: int = 20,
        image_size: int = 512
    ):
        """Run training"""
        print(f"Starting training for {num_epochs} epochs...")

        # Dataset
        dataset = EyebrowDataset(
            data_dir=data_dir,
            tokenizer=self.tokenizer,
            size=image_size
        )

        dataloader = DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=True,
            num_workers=0
        )

        # Optimizer
        optimizer = torch.optim.AdamW(
            self.unet.parameters(),
            lr=self.learning_rate,
            weight_decay=1e-2
        )

        # LR scheduler
        lr_scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
            optimizer,
            T_max=num_epochs * len(dataloader)
        )

        # Prepare with accelerator
        self.unet, optimizer, dataloader, lr_scheduler = self.accelerator.prepare(
            self.unet, optimizer, dataloader, lr_scheduler
        )

        self.vae.to(self.accelerator.device)
        self.text_encoder.to(self.accelerator.device)

        # Training loop
        global_step = 0

        for epoch in range(num_epochs):
            self.unet.train()
            epoch_loss = 0
            progress_bar = tqdm(dataloader, desc=f"Epoch {epoch+1}/{num_epochs}")

            for batch in progress_bar:
                with self.accelerator.accumulate(self.unet):
                    # Encode images to latents
                    latents = self.vae.encode(
                        batch["pixel_values"].to(dtype=torch.float16)
                    ).latent_dist.sample()
                    latents = latents * self.vae.config.scaling_factor

                    # Sample noise
                    noise = torch.randn_like(latents)

                    # Sample timesteps
                    timesteps = torch.randint(
                        0,
                        self.noise_scheduler.config.num_train_timesteps,
                        (latents.shape[0],),
                        device=latents.device
                    )

                    # Add noise
                    noisy_latents = self.noise_scheduler.add_noise(
                        latents, noise, timesteps
                    )

                    # Get text embeddings
                    encoder_hidden_states = self.text_encoder(
                        batch["input_ids"]
                    )[0]

                    # Predict noise
                    noise_pred = self.unet(
                        noisy_latents,
                        timesteps,
                        encoder_hidden_states
                    ).sample

                    # Calculate loss
                    loss = torch.nn.functional.mse_loss(
                        noise_pred.float(),
                        noise.float(),
                        reduction="mean"
                    )

                    # Backward
                    self.accelerator.backward(loss)
                    optimizer.step()
                    lr_scheduler.step()
                    optimizer.zero_grad()

                    epoch_loss += loss.detach().item()
                    global_step += 1

                    progress_bar.set_postfix({"loss": loss.item()})

            avg_loss = epoch_loss / len(dataloader)
            print(f"Epoch {epoch+1} - Average Loss: {avg_loss:.4f}")

            # Save checkpoint
            if (epoch + 1) % save_every == 0:
                self._save_checkpoint(f"checkpoint-{epoch+1}")

        # Final save
        self._save_checkpoint("final")
        print("Training complete!")

    def _save_checkpoint(self, name: str):
        """Save LoRA weights"""
        save_path = self.output_dir / name
        save_path.mkdir(parents=True, exist_ok=True)

        unwrapped = self.accelerator.unwrap_model(self.unet)
        unwrapped.save_pretrained(save_path)

        print(f"Saved checkpoint: {save_path}")


def prepare_dataset(raw_dir: str, output_dir: str):
    """Prepare training dataset from raw images"""
    raw_path = Path(raw_dir)
    output_path = Path(output_dir)

    (output_path / "images").mkdir(parents=True, exist_ok=True)
    (output_path / "captions").mkdir(parents=True, exist_ok=True)

    idx = 0
    for img_path in raw_path.glob("*"):
        if img_path.suffix.lower() not in ['.png', '.jpg', '.jpeg', '.webp']:
            continue

        # Load and process image
        img = Image.open(img_path).convert("RGB")

        # Center crop to square
        w, h = img.size
        min_dim = min(w, h)
        left = (w - min_dim) // 2
        top = (h - min_dim) // 2
        img = img.crop((left, top, left + min_dim, top + min_dim))

        # Resize to 512x512
        img = img.resize((512, 512), Image.LANCZOS)

        # Save
        output_name = f"eyebrow_{idx:04d}.png"
        img.save(output_path / "images" / output_name)

        # Generate caption
        name_lower = img_path.stem.lower()
        tags = ["ohwx_eyebrow"]

        if "bold" in name_lower:
            tags.append("bold eyebrow")
        if "natural" in name_lower:
            tags.append("natural eyebrow")
        if "arch" in name_lower:
            tags.append("arched shape")
        if "straight" in name_lower:
            tags.append("straight shape")
        if "emboss" in name_lower or "엠보" in name_lower:
            tags.append("embossed texture, hair stroke")
        if "shading" in name_lower or "수지" in name_lower:
            tags.append("powder shading, soft gradient")

        tags.extend(["realistic", "natural skin texture", "high quality"])

        caption = ", ".join(tags)
        (output_path / "captions" / f"eyebrow_{idx:04d}.txt").write_text(caption)

        idx += 1

    print(f"Prepared {idx} images in {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Train LoRA for eyebrow synthesis")

    subparsers = parser.add_subparsers(dest="command")

    # Prepare command
    prep_parser = subparsers.add_parser("prepare", help="Prepare training dataset")
    prep_parser.add_argument("--raw_dir", required=True, help="Raw images directory")
    prep_parser.add_argument("--output_dir", required=True, help="Output directory")

    # Train command
    train_parser = subparsers.add_parser("train", help="Train LoRA")
    train_parser.add_argument("--data_dir", required=True, help="Training data directory")
    train_parser.add_argument("--output_dir", default="models/lora/eyebrow_v1")
    train_parser.add_argument("--epochs", type=int, default=100)
    train_parser.add_argument("--batch_size", type=int, default=1)
    train_parser.add_argument("--lr", type=float, default=1e-4)
    train_parser.add_argument("--lora_rank", type=int, default=32)
    train_parser.add_argument("--save_every", type=int, default=20)

    args = parser.parse_args()

    if args.command == "prepare":
        prepare_dataset(args.raw_dir, args.output_dir)

    elif args.command == "train":
        trainer = LoRATrainer(
            output_dir=args.output_dir,
            lora_rank=args.lora_rank,
            learning_rate=args.lr
        )

        trainer.train(
            data_dir=args.data_dir,
            num_epochs=args.epochs,
            batch_size=args.batch_size,
            save_every=args.save_every
        )

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
