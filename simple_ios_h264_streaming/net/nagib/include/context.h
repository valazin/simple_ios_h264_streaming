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

enum StreamType
{
    VideoStream = 0,
    AudioStream = 1
};

typedef struct FrameContext
{
    int isKeyFrame;
    long pts;
    long dts;
    enum StreamType streamType;
} FrameContext;

#ifdef __cplusplus
}
#endif

#endif // CONTEXT_H
