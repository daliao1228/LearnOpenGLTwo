
attribute vec3 position;
attribute vec3 intputColor;

varying vec3 outputColor;

void main()
{
    gl_Position = position;
    outputColor = inputColor;
}
