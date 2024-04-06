#ifndef IMAGE_HPP_
#define IMAGE_HPP_

#include "sli.h"

enum ImageBpp { kImageBpp8 = 8, kImageBpp32 = 32 };

class Image {
public:
  Image();
	Image(int width, int height, ImageBpp bpp);
	Image(int width, int height, ImageBpp bpp, int num_frames);
  Image(const char *file_name, ImageBpp bpp);

  // Deep-copies another image into this one.
  // All non-pointer SLI header fields are copied. Only those pointees in the SLI header that are intrinsically tied to
  // the image data are deep-copied.
  // Fields that are deep-copied: image frame pointers, integral image pointer.
  // Fields that are not deep-copied: span buffer pointer, lighting table pointer, alpha map pointer.
  // The fields that are not copied are not considered part of the image state. Therefore, any Image API parts depending
  // on them should either get them as arguments, e.g. blitting with alpha map or rendering a grid with a lighting table,
  // or fill them out internally for any subsequent calls that consume them, e.g. rendering a 3D scene.
  Image(const Image &other);
  Image &operator=(const Image &other);

  virtual ~Image();

  SLI *sli() { return sli_; }

  int width() const { return sli_->SLIXSize; }
  int height() const { return sli_->SLIYSize; }
  ImageBpp bpp() const;

protected:
  void CreateSLIOrThrow(int width, int height, ImageBpp bpp, int num_frames);
  void Destroy();

private:
  SLI *sli_;
};

#endif /* IMAGE_HPP_ */