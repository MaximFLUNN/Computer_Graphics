using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using OpenTK;

namespace Tomograff
{
    public partial class Form1 : Form
    {
        Bin bin = new Bin();
        View view = new View();
        bool loaded = false;
        int currentLayer = 1;
        int FrameCount;
        int renderType = 0;
        bool reload = false;
        DateTime NextFPSUpdate = DateTime.Now.AddSeconds(1);
        public Form1() {
            InitializeComponent();
        }

        void Application_Idle(object sender, EventArgs e)
        {
            while (glControl1.IsIdle)
            {
                displayFPS();
                glControl1.Invalidate();
            }
        }

        void displayFPS()
        {
            if (DateTime.Now >= NextFPSUpdate)
            {
                this.Text = String.Format("CT Visualizer (fps={0})", FrameCount);
                NextFPSUpdate = DateTime.Now.AddSeconds(1);
                FrameCount = 0;
            }
            FrameCount++;
        }

        private void button1_Click(object sender, EventArgs e) {
            OpenFileDialog dialog = new OpenFileDialog();
            if (dialog.ShowDialog() == DialogResult.OK) {
                string str = dialog.FileName;
                bin.readBIN(str);
                view.SetupView(glControl1.Width, glControl1.Height);
                loaded = true;
                glControl1.Invalidate();
                reload = true;
            }
        }

        private void glControl1_Paint(object sender, PaintEventArgs e) {
            if (loaded) {
                if (reload) {
                    if (renderType == 0) {
                        view.DrawQuads(currentLayer, trackBar3.Value, trackBar2.Value);
                        glControl1.SwapBuffers();
                    }
                    else if (renderType == 1) {
                        view.generateTextureImage(currentLayer, trackBar3.Value, trackBar2.Value);
                        view.Load2dTexture();
                        view.DrawTexture();
                        glControl1.SwapBuffers();
                    }
                    else if (renderType == 2) {
                        view.DrawQuadStrip(currentLayer, trackBar3.Value, trackBar2.Value);
                        glControl1.SwapBuffers();
                    }
                    reload = false;
                }
            }
        }

        private void trackBar1_Scroll(object sender, EventArgs e) {
            currentLayer = trackBar1.Value;
            reload = true;
        }

        private void Form1_Load(object sender, EventArgs e) {
            Application.Idle += Application_Idle;
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (renderType == 0)
            {
                renderType = 1;
                button2.Text = "Render: Texture";
            }
            else if (renderType == 1)
            {
                renderType = 2;
                button2.Text = "Render: QuadStrip";
            }
            else if (renderType == 2)
            {
                renderType = 0;
                button2.Text = "Render: Quads";
            }
            reload = true;
        }

        private void trackBar3_Scroll(object sender, EventArgs e)
        {
            reload = true;
        }

        private void trackBar2_Scroll(object sender, EventArgs e)
        {
            reload = true;
        }
    }
}
