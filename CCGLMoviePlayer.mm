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
    
    orientation = NORMAL;
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
    
//    currentFrame = 0;
}


void CCGLMoviePlayer::draw( Area area ) {
    
	// this pair of lines is the standard way to clear the screen in OpenGL
	gl::clear( Color( 0.0f, 0.0f, 0.0f ), true );
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    if (shouldPlay) {
        
        if (!isLoaded) return;
        
        loadMovieFrame();
        
        if (mTex) {
            
            /** 
             * Following Transform works for landscape video in iOS portrait mode
             **/
            
            // don't use gl::pushMatrices() if you're not adjusting the camera,
            // use gl::pushModelView() instead. See point 4 of Common OpenGL Pitfalls
            gl::pushModelView();
            
            switch (orientation) {
                case NORMAL:
                    
                    break;
                case ROTATE_LEFT:

                    cout << "Rotate_left transform not working yet" << endl;
//                    // now apply transformations in reverse order
//                    gl::translate( -mTex.getHeight(), area.getHeight() );
//                    gl::rotate( -90.0f );
                    
                    break;
                case ROTATE_RIGHT:
                    
                    // now apply transformations in reverse order
                    gl::translate( area.getWidth(), 0 );
                    gl::rotate( 90.0f );
                                        
                    swap(area.x2, area.y2);

                    break;
                case UPSIDE_DOWN:
                    cout << "Upside down transform not working yet" << endl;
//                    gl::rotate( 180.0f );

                    break;
                    
                default:
                    break;
            }
            
            Area sourceBounds = Area( 0, 0, mTex.getWidth(), mTex.getHeight() );
            Area destinationBounds = Area::proportionalFit( sourceBounds, area,
                                                           true, true );
            
            gl::draw( mTex, sourceBounds, destinationBounds );
    
            // restore modelview matrix
            gl::popModelView();
        }
    }
}

void CCGLMoviePlayer::close() {
    
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
                            }
                        });
         
         isLoaded = YES;
         
//         cout << "movie reader started reading" << endl;
     }];
}

void CCGLMoviePlayer::loadMovieFrame()
{
    
    if (movieReader.status == AVAssetReaderStatusReading)
    {
        
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
    }
}


void CCGLMoviePlayer::addImageRef(CGImageRef *img)
{
	if ( !img ) throw ImageIoExceptionFailedLoad();

    // turn CGImageRef into texture
    mTex = gl::Texture( cinder::cocoa::createImageSource( *img ) );
}


//swap returns void, and takes in two variables as a reference.
static void swap( int &a, int &b )
{
    int tmp; //Create a tmp int variable for storage
    
    tmp = a;
    a = b;
    b = tmp;
    
    return;
}

