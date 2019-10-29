#ifndef SENDERWRAPPER_H
#define SENDERWRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include "context.h"

struct sender;
typedef struct sender sender_t;

sender_t *sender_create(const char* host, int port, int timeout_sec);
void sender_destroy(sender_t *sender);

int sender_connect(sender_t *sender, const char* stream_id, VideoContext videoContext, AudioContext audioContext, int attemps_count);
void sender_disconnect(sender_t *sender);

void sender_send_frame(sender_t *sender, char* buffer, long buffer_size, FrameContext frameContext);

#ifdef __cplusplus
}
#endif

#endif // SENDERWRAPPER_H
