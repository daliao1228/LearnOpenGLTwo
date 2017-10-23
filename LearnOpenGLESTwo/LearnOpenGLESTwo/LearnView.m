//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/11.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "LearnView.h"
#import <OpenGLES/ES3/gl.h>

@interface LearnView()

@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLuint fragmentUniform;


@property (nonatomic, assign) GLuint position;
@property (nonatomic, assign) GLuint inputColor;

@property (nonatomic, strong) NSTimer *renderTimer;
@property (nonatomic, assign) CGFloat testInput;

@end

@implementation LearnView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)dealloc {
    [self destoryRenderAndFrameBuffer];
    [self stopRender];
}

- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self setupVBOAndShaders];
    
    [self startRenderIfNeedRepeat:NO];
}

- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)setupVBOAndShaders {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    self.shaderProgram = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv_varing" ofType:@"vsh"]
                                 fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf_varing" ofType:@"fsh"]];
    
    glLinkProgram(self.shaderProgram);
    glUseProgram(self.shaderProgram);
    
    GLfloat attrArr[] =
    {
        -0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f,
         0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f,
         0.0f,  0.5f, 0.0f, 0.0f, 0.0f, 1.0f
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    self.position = glGetAttribLocation(self.shaderProgram, "position");
    glEnableVertexAttribArray(self.position);
    glVertexAttribPointer(self.position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    
    self.inputColor = glGetAttribLocation(self.shaderProgram, "inputColor");
    glEnableVertexAttribArray(self.inputColor);
    glVertexAttribPointer(self.inputColor, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void *)(3 * sizeof(float))); // 最后一个参数终于理解了，是指的需要一个从头开始的偏移
    
    
    
//    self.fragmentUniform = glGetUniformLocation(self.shaderProgram, "ourColor");// uniform相当于常量，他的输入在整个一次shader运行（每一个像素遍历一遍）的时候是不会变的，通过这种方式来绑定CPU和GPU上对应的参数对应的shader为shaderf_Uniform.fsh，fragment Shader里面无法声明变量，只能声明uniform或者vertexShader传进来一个 varying
    
}

- (void)startRenderIfNeedRepeat:(BOOL)needRepeat {
    if (needRepeat) {
        if (self.renderTimer) {
            [self stopRender];
        }
        self.renderTimer = [NSTimer scheduledTimerWithTimeInterval:0.033 repeats:YES block:^(NSTimer *timer){
            [self render];
        }];
    } else {
        [self render];
    }
}

- (void)stopRender {
    [self.renderTimer invalidate];
    self.renderTimer = nil;
}

- (void)render {
   
}

- (void)renderVarying {
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderUniform {
    self.testInput += 0.1;
    float greenValue = sin(self.testInput) / 2.0f + 0.5f;
    glUniform4f(self.fragmentUniform, 0.0f, greenValue, 0.0f, 1.0f);//实时改变每次渲染的颜色
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (GLuint)loadVertexShaders:(NSString *)vertexShaderPath fragmentShaders:(NSString *)fragmentShaderPath {
    
    GLuint shaderProgram = glCreateProgram();
    
    GLuint vertexShader = [self compileShaderWithFilePath:vertexShaderPath shaderType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithFilePath:fragmentShaderPath shaderType:GL_FRAGMENT_SHADER];
    
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return shaderProgram;
}

- (GLuint)compileShaderWithFilePath:(NSString *)filePath shaderType:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const GLchar *source = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (source == NULL) {
        NSLog(@"shader file is not exist");
        return 0;
    }
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[512];
        glGetShaderInfoLog(shader, 512, NULL, messages);
        NSString *errorMessage = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", errorMessage);
    }
    return shader;
}

- (void)checkGLError {
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        NSLog(@"GL error: 0x%x", glError);
    }
}

@end
