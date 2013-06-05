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

enum movieOrientation { NORMAL, ROTATE_LEFT, ROTATE_RIGHT, UPSIDE_DOWN };

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
    
    movieOrientation orientation;
    
protected:
    
    gl::Texture mTex;
    
    AVAssetReader *movieReader;
    
    void readMovie(NSURL *url);
    void loadMovieFrame();
    void addImageRef(CGImageRef *img);
    
    bool shouldPlay;
    bool shouldLoop;
//    int currentFrame;
//    float mFrameRate;
};
