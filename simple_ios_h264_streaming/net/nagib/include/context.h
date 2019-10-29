#ifndef CONTEXT_H
#define CONTEXT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Timebase
{
    int num;
    int den;
} Timebase;

typedef struct VideoContext
{
    Timebase timebase;
    int frameWidth;
    int frameHeight;
} VideoContext;

typedef struct AudioContext
{
    Timebase timebase;
    int sampleRate;
    int channelsCount;
} AudioContext;

typedef struct FrameContext
{
    char isKeyFrame;
    long pts;
    long dts;
    char isVideoFrame;
} FrameContext;

#ifdef __cplusplus
}
#endif

#endif // CONTEXT_H
