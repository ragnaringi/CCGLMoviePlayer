//
//  CCGLMoviePlayer.h
//  westfjords
//
//  Created by Ragnar Hrafnkelsson on 04/06/2013.
//
//

#pragma once

#import <AVFoundation/AVFoundation.h>
#include "cinder/app/App.h"
#include "cinder/gl/gl.h"
#include "cinder/gl/Texture.h"

using namespace ci;
using namespace ci::app;
using namespace std;

class CCGLMoviePlayer {
public:
    CCGLMoviePlayer();
    void loadMovie( NSURL *movieURL );
    void play( bool loop );
    void play();
    void stop();
    void pause();
    void close();
    
    void draw(Area area);
    
    bool isLoaded;
    
protected:
    
    gl::Texture mTex;
    
//    vector<gl::Texture> mVideoFrames;
    vector<Surface> mVideoFrames;
    
    AVAssetReader *movieReader;
    
    void readMovie(NSURL *url);
    void loadMovieFrames();
    void addImageRef(CGImageRef *img);
    
    bool shouldPlay;
    bool shouldLoop;
    int currentFrame;
    float mFrameRate;
};
