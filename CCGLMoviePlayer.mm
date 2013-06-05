//
//  CCGLMoviePlayer.m
//  westfjords
//
//  Created by Ragnar Hrafnkelsson on 04/06/2013.
//
//

#import "CCGLMoviePlayer.h"

CCGLMoviePlayer::CCGLMoviePlayer() {}

void CCGLMoviePlayer::loadMovie( NSURL *movieURL ) {
    
    readMovie( movieURL );
    
//    frameRate = _mFrameRate;
    
    shouldLoop = NO;
    shouldPlay = NO;
}

void CCGLMoviePlayer::play(bool loop) {
    
    cout << "play" << endl;
    
    shouldLoop = loop;
    
    shouldPlay = YES;
}

void CCGLMoviePlayer::play() {
    
    shouldLoop = NO;
    
    shouldPlay = YES;
}

void CCGLMoviePlayer::pause() {
    
    shouldPlay = NO;
}

void CCGLMoviePlayer::stop() {
    
    shouldPlay = NO;
    
    currentFrame = 0;
}


void CCGLMoviePlayer::draw( Area area ) {
	// this pair of lines is the standard way to clear the screen in OpenGL
	gl::clear( Color( 0.9f, 0.9f, 0.9f ), true );
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    if (shouldPlay) {
        
        if (!isLoaded) return;
        
//        mTex = &mVideoFrames[currentFrame]; // Does not crash when beyond vector size
        
//        currentFrame++;
//        if (currentFrame >= mVideoFrames.size()) {
//            
//            if (shouldLoop) currentFrame = 0;
//    
//            else return;
//        }
        
        loadMovieFrames();
        
        if (mTex) {
            
            Area sourceBounds = Area( 0, 0, mTex.getWidth(), mTex.getHeight() );
            Area destinationBounds = Area::proportionalFit( sourceBounds, area,
                                                           true, true );
            
            gl::draw( mTex, sourceBounds, destinationBounds );
        }
    }
}

void CCGLMoviePlayer::close() {
    
    mVideoFrames.clear();
    movieReader= nil;
}



/**
 *  Loading movie
 */


void CCGLMoviePlayer::readMovie(NSURL *url)
{
	AVURLAsset * asset = [AVURLAsset URLAssetWithURL:url options:nil];
	[asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:
     ^{
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            AVAssetTrack * videoTrack = nil;
                            NSArray * tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                            if ([tracks count] == 1)
                            {
                                videoTrack = [tracks objectAtIndex:0];
                                
                                // Set frame rate
//                                mFrameRate = videoTrack.nominalFrameRate;
                                
                                NSError * error;
                                
                                // _movieReader is a member variable
                                movieReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
                                if (error)
                                    NSLog(@"%@", [error localizedDescription]);
                                
                                NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
                                NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
                                NSDictionary* videoSettings =
                                [NSDictionary dictionaryWithObject:value forKey:key];
                                
                                [movieReader addOutput:[AVAssetReaderTrackOutput
                                                         assetReaderTrackOutputWithTrack:videoTrack
                                                         outputSettings:videoSettings]];
                                [movieReader startReading];
                                
                                // NOTE(Ragnar): Before this called to load all frames into vector<gl::Texture>
                                // Load movie frames was a while loop
                                //loadMovieFrames();
                            }
                        });
         
         // Allow to buffer a little bit before playing?
//         usleep(1000000);
         
         isLoaded = YES;
         
         cout << "movie reader started reading" << endl;
     }];
}

void CCGLMoviePlayer::loadMovieFrames()
{
    
    // while loop to load all frames into vector
    if (movieReader.status == AVAssetReaderStatusReading)
    {
//        cout << "loadframe" << endl;
        
        AVAssetReaderTrackOutput * output = [movieReader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer)
        {
            @autoreleasepool {
                
                CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                
                // Lock the image buffer
                CVPixelBufferLockBaseAddress(imageBuffer,0);
                
                // Get information of the image
                uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
                size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                size_t width = CVPixelBufferGetWidth(imageBuffer);
                size_t height = CVPixelBufferGetHeight(imageBuffer);
                
                /*Create a CGImageRef from the CVImageBufferRef*/
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
                CGImageRef newImage = CGBitmapContextCreateImage(newContext);
                
                /*We release some components*/
                CGContextRelease(newContext);
                CGColorSpaceRelease(colorSpace);
                
                // Pass the image ref to the vector of textures
                addImageRef( &newImage );
                
                /*We relase the CGImageRef*/
                CGImageRelease(newImage);
                
                // Unlock the image buffer
                CVPixelBufferUnlockBaseAddress(imageBuffer,0);
                CFRelease(sampleBuffer);
            }
        }
        
        // NOTE(Ragnar): Call itself if in while loop
        //loadMovieFrames();
    }
    
    /* if in while loop set as loaded when finished */
//    movieReader = nil;
//    isLoaded = YES;
}


void CCGLMoviePlayer::addImageRef(CGImageRef *img)
{
	if ( !img ) throw ImageIoExceptionFailedLoad();
    
    mTex = gl::Texture( cinder::cocoa::createImageSource( *img ) );
    
//    Surface temp2( temp  );
////    gl::Texture temp = gl::Texture( cinder::cocoa::createImageSource( *img ) );
//    
//    // turn CGImageRef into texture
//    mVideoFrames.push_back( temp );
}
