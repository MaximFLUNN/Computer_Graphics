using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OpenTK;
using OpenTK.Graphics.OpenGL;

namespace Tomograff
{
    internal class View
    {
        int VBOtexture;
        Bitmap textureImage;
        public void Load2dTexture()
        {
            GL.BindTexture(TextureTarget.Texture2D, VBOtexture);
            BitmapData data = textureImage.LockBits(
                new System.Drawing.Rectangle(0, 0, textureImage.Width, textureImage.Height),
                ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format32bppArgb);

            GL.TexImage2D(TextureTarget.Texture2D, 0, PixelInternalFormat.Rgba,
                data.Width, data.Height, 0, OpenTK.Graphics.OpenGL.PixelFormat.Bgra,
                PixelType.UnsignedByte, data.Scan0);

            textureImage.UnlockBits(data);

            GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter,
                (int)TextureMinFilter.Linear);
            GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter,
                (int)TextureMagFilter.Linear);

            ErrorCode Er = GL.GetError();
            string str = Er.ToString();
        }

        public void generateTextureImage(int layerNumber, int min, int max)
        {
            textureImage = new Bitmap(Bin.X, Bin.Y);
            for (int i = 0; i < Bin.X; i++)
            {
                for (int j = 0; j < Bin.Y; j++)
                {
                    int pixelNumber = i + j * Bin.X + layerNumber * Bin.X * Bin.Y;
                    textureImage.SetPixel(i, j, TransferFunction(Bin.array[pixelNumber], min, max));
                }
            }
        }

        public void DrawTexture()
        {
            GL.Clear(ClearBufferMask.ColorBufferBit | ClearBufferMask.DepthBufferBit);
            GL.Enable(EnableCap.Texture2D);
            GL.BindTexture(TextureTarget.Texture2D, VBOtexture);

            GL.Begin(BeginMode.Quads);
            GL.Color3(Color.White);
            GL.TexCoord2(0.0f, 0.0f);
            GL.Vertex2(0, 0);
            GL.TexCoord2(0f, 1f);
            GL.Vertex2(0, Bin.Y);
            GL.TexCoord2(1f, 1f);
            GL.Vertex2(Bin.X, Bin.Y);
            GL.TexCoord2(1f, 0f);
            GL.Vertex2(Bin.X, 0);
            GL.End();

            GL.Disable(EnableCap.Texture2D);
        }

        public void SetupView(int width, int height)
        {
            GL.ShadeModel(ShadingModel.Smooth);
            GL.MatrixMode(MatrixMode.Projection);
            GL.LoadIdentity();
            GL.Ortho(0, Bin.X, 0, Bin.Y, -1, 1);
            GL.Viewport(0, 0, width, height);
        }

        public void DrawQuads(int layerNumber, int min, int max)
        {
            GL.Clear(ClearBufferMask.ColorBufferBit | ClearBufferMask.DepthBufferBit);
            GL.Begin(BeginMode.Quads);
            for (int x_coord = 0; x_coord < Bin.X - 1; x_coord++)
            {
                GL.Begin(PrimitiveType.QuadStrip);
                for (int y_coord = 0; y_coord < Bin.Y - 1; y_coord++)
                {
                    short value;
                    //first vershina;
                    value = Bin.array[x_coord + y_coord * Bin.X +
                        layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord, y_coord);
                    //second vershina
                    value = Bin.array[x_coord + (y_coord + 1) * Bin.X
                        + layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord, y_coord + 1);
                    //third vershina
                    value = Bin.array[x_coord + 1 + (y_coord + 1) * Bin.X
                        + layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord + 1, y_coord + 1);
                    //fourth vershina
                    value = Bin.array[x_coord + 1 + y_coord * Bin.X
                        + layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord + 1, y_coord);

                }
            }
            GL.End();
        }

        public void DrawQuadStrip(int layerNumber, int min, int max) {
            GL.Clear(ClearBufferMask.ColorBufferBit | ClearBufferMask.DepthBufferBit);
            GL.Begin(BeginMode.QuadStrip);
            for (int x_coord = 0; x_coord < Bin.X - 1; x_coord++) {
                GL.Begin(PrimitiveType.QuadStrip);
                for (int y_coord = 0; y_coord < Bin.Y - 1; y_coord++) {
                    short value;
                    value = Bin.array[x_coord + y_coord * Bin.X + layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord, y_coord);

                    value = Bin.array[x_coord + 1 + y_coord * Bin.X + layerNumber * Bin.X * Bin.Y];
                    GL.Color3(TransferFunction(value, min, max));
                    GL.Vertex2(x_coord + 1, y_coord);
                }
                GL.End();
            }
        }

        Color TransferFunction(short value, int min, int max_)
        {
            //int min = 0;
            //int max = 2000;
            int max = min + max_;
            int newVal = Clamp((value - min) * 255 / (max - min), 0, 255);
            return Color.FromArgb(255, newVal, newVal, newVal);
        }

        public int Clamp(int value, int min, int max)
        {
            return value < min ? min : value > max ? max : value;
        }
    }
}
