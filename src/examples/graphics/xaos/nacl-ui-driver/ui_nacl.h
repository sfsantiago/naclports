#ifndef UI_NACL_H


#define BITS_PER_PIXEL 32
#define BYTES_PER_PIXEL (BITS_PER_PIXEL/8)

/* Get screen width and height */
int GetWidth();
int GetHeight();

/* flush video buffer to screen */
void CopyImageDataToVideo(void* data);
/* get next ppapi event to process, may block if wait == 1 */
struct PP_InputEvent;
int GetEvent(struct PP_InputEvent* event, int wait);

/* these headers need an sdk update before they can be used */
#if 0
#include <nacl/nacl_check.h>
#include <nacl/nacl_log.h>
#else
#define CHECK(cond) do { if (!cond) {puts("ABORT: " #cond "\n"); abort();}} while(0)
#define NaClLog(lev, ...)  fprintf(stderr, __VA_ARGS__)
#endif

#endif /* UI_NACL_H */
