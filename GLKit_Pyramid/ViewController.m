//
//  ViewController.m
//  GLKit_Pyramid
//
//  Created by 鲸鱼集团技术部 on 2020/8/1.
//  Copyright © 2020 com.sanqi.net. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    dispatch_source_t timer;
}
@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) GLKBaseEffect *myEffect;

@property (nonatomic, assign) int count;

//旋转度数
@property (nonatomic, assign) float xDegree;
@property (nonatomic, assign) float yDegree;
@property (nonatomic, assign) float zDegree;

//是否旋转x, y, z
@property (nonatomic, assign) BOOL xB;
@property (nonatomic, assign) BOOL yB;
@property (nonatomic, assign) BOOL zB;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //1. 新建图层
    [self setupContext];

    //2. 渲染图形
    [self render];

    //3.加载纹理数据
    [self setupTexture];
}

- (void)setupTexture {
    //1.获取纹理图片路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"xiannv" ofType:@"jpg"];

    //2.设置纹理参数
    //纹理坐标原点是左下角，但是图片的显示原点是左上角
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];

    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];

    //3.使用苹果GLKit 提供的GLKBaseEffect 完成着色器工作
    self.myEffect.texture2d0.enabled = GL_TRUE;
    self.myEffect.texture2d0.name = textureInfo.name;
}

//1. 新建图层
- (void)setupContext {
    //1.新建OpenGL ES 上下文
    self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    GLKView *view = (GLKView *)self.view;
    view.context = self.myContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.myContext];
    //开启深度测试
    glEnable(GL_DEPTH_TEST);
}

//2. 渲染图形
- (void)render {

    //1.顶点数据
    //前3个元素是顶点数据，中间3个是颜色值，最后2个是纹理坐标
        GLfloat attrArr[] =
        {
            -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,       0.0f, 1.0f,//左上
            0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,       1.0f, 1.0f,//右上
            -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,       0.0f, 0.0f,//左下

            0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,       1.0f, 0.0f,//右下
            0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,       0.5f, 0.5f,//顶点
        };

//    GLfloat attrArr[] =
//    {
//        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
//        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
//        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
//
//        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
//        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
//    };

    //2.索引绘图
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };

    //顶点个数
    self.count = sizeof(indices) / sizeof(GLuint);

    //将顶点数组放入数组缓冲区中 GL_ARRAY_BUFFER
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);

    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    //使用顶点数据
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, NULL);

    //使用颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);

    //纹理坐标数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);

    //着色器
    self.myEffect = [[GLKBaseEffect alloc] init];
    //投影视图
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 100.0);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0, 1.0, 1.0);
    self.myEffect.transform.projectionMatrix = projectionMatrix;

    //模型视图
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.0);
    self.myEffect.transform.modelviewMatrix = modelViewMatrix;

    //定时器
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        self.xDegree += 0.1 * self.xB;
        self.yDegree += 0.1 * self.yB;
        self.zDegree += 0.1 * self.zB;
    });
    dispatch_resume(timer);

}

-(void)update {
    GLKMatrix4 modeViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.5);
    modeViewMatrix = GLKMatrix4RotateX(modeViewMatrix, self.xDegree);
    modeViewMatrix = GLKMatrix4RotateY(modeViewMatrix, self.yDegree);
    modeViewMatrix = GLKMatrix4RotateZ(modeViewMatrix, self.zDegree);

    self.myEffect.transform.modelviewMatrix = modeViewMatrix;
}

// 场景数据变化
//- (void)glkViewControllerUpdate:(GLKViewController *)controller {
//    GLKMatrix4 modeViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.5);
//    modeViewMatrix = GLKMatrix4RotateX(modeViewMatrix, self.xDegree);
//    modeViewMatrix = GLKMatrix4RotateY(modeViewMatrix, self.yDegree);
//    modeViewMatrix = GLKMatrix4RotateZ(modeViewMatrix, self.zDegree);
//
//    self.myEffect.transform.modelviewMatrix = modeViewMatrix;
//}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self.myEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

- (IBAction)XButtonClick:(id)sender {
    _xB = !_xB;
}
- (IBAction)YButtonClick:(id)sender {
    _yB = !_yB;
}
- (IBAction)ZButtonCLick:(id)sender {
    _zB = !_zB;
}

@end
