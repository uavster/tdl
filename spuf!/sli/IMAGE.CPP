#include "image.hpp"
#include "except.hpp"
#include "string.hpp"

void Image::CreateSLIOrThrow(int width, int height, ImageBpp bpp, int num_frames) {
  sli_ = CreateSLI(width, height, static_cast<int>(bpp), num_frames);
  if (sli_ == NULL) {
    throw MallocException();
  }
}

Image::Image() : sli_(NULL) {
}

Image::Image(int width, int height, ImageBpp bpp, int num_frames) {
  CreateSLIOrThrow(width, height, bpp, num_frames);
}

Image::Image(int width, int height, ImageBpp bpp) {
  CreateSLIOrThrow(width, height, bpp, /*num_frames=*/1);
}

Image::Image(const char *file_name, ImageBpp bpp) {
  sli_ = LoadGFX(file_name, static_cast<int>(bpp));
  if (sli_ == NULL) {
    throw Exception(std::string("Unable to load image from file \"") + file_name + "\"");
  }
}

void Image::Destroy() {
  if (sli_ == NULL) {
    return;
  }
  DestroySLI(sli_);
  sli_ = NULL;
}

Image::~Image() {
  Destroy();
}

Image::Image(const Image &other) {
  if (other.sli_ == NULL) { return; }
  sli_ = CreateSLIDeepCopy(other.sli_);
  if (sli_ == NULL) {
    throw Exception("Unable to create deep copy");
  }
}

Image &Image::operator=(const Image &other) {
  if (this == &other) {
    return *this;
  }
  Destroy();
  if (other.sli_ != NULL) {
    sli_ = CreateSLIDeepCopy(other.sli_);
    if (sli_ == NULL) {
      throw Exception("Unable to create deep copy");
    }
  }
  return *this;
}

ImageBpp Image::bpp() const {
  switch(sli_->SLIColorBits) {
    case 1: return kImageBpp8;
    case 4: return kImageBpp32;
  }
  throw Exception("Unsupported bits per pixel");
}

void Image::CopyPaletteFrom(const SLI *sli) {
  SetPalette(sli->SLIPalette);
}

void Image::SetPalette(const DWORD *palette_buffer) {
  memcpy(sli_->SLIPalette, palette_buffer, 256 * 4);
}
