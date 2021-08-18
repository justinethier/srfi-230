#include "cyclone/types.h"
// From https://stackoverflow.com/a/16421577/101258
typedef union {
  atomic_flag flag;
  object bits;
} object_box_t;
