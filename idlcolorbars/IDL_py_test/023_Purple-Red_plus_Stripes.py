from matplotlib.colors import LinearSegmentedColormap
from numpy import nan, inf
cm_data = [[0., 0., 0.],
[0., 0., 0.],
[0.498039, 0.498039, 0.498039],
[0.74902, 0., 0.74902],
[0.737255, 0., 0.752941],
[0.729412, 0., 0.752941],
[0.721569, 0., 0.756863],
[0.713725, 0., 0.760784],
[0.701961, 0., 0.764706],
[0.694118, 0., 0.764706],
[0.54902, 0., 0.615686],
[0.541176, 0., 0.615686],
[0.666667, 0., 0.776471],
[0.658824, 0., 0.776471],
[0.647059, 0., 0.780392],
[0.639216, 0., 0.784314],
[0.631373, 0., 0.788235],
[0.619608, 0., 0.792157],
[0.611765, 0., 0.792157],
[0.603922, 0., 0.796078],
[0.47451, 0., 0.639216],
[0.466667, 0., 0.643137],
[0.576471, 0., 0.803922],
[0.568627, 0., 0.807843],
[0.556863, 0., 0.811765],
[0.54902, 0., 0.815686],
[0.541176, 0., 0.815686],
[0.529412, 0., 0.819608],
[0.521569, 0., 0.823529],
[0.513725, 0., 0.827451],
[0.403922, 0., 0.662745],
[0.396078, 0., 0.666667],
[0.486275, 0., 0.835294],
[0.478431, 0., 0.839216],
[0.466667, 0., 0.843137],
[0.458824, 0., 0.843137],
[0.45098, 0., 0.847059],
[0.439216, 0., 0.85098],
[0.431373, 0., 0.854902],
[0.423529, 0., 0.854902],
[0.329412, 0., 0.686275],
[0.321569, 0., 0.690196],
[0.396078, 0., 0.866667],
[0.388235, 0., 0.866667],
[0.376471, 0., 0.870588],
[0.368627, 0., 0.87451],
[0.360784, 0., 0.878431],
[0.34902, 0., 0.882353],
[0.341176, 0., 0.882353],
[0.333333, 0., 0.886275],
[0.258824, 0., 0.709804],
[0.25098, 0., 0.713725],
[0.305882, 0., 0.894118],
[0.298039, 0., 0.898039],
[0.286275, 0., 0.901961],
[0.278431, 0., 0.905882],
[0.270588, 0., 0.905882],
[0.258824, 0., 0.909804],
[0.25098, 0., 0.913725],
[0.243137, 0., 0.917647],
[0.184314, 0., 0.737255],
[0.180392, 0., 0.737255],
[0.215686, 0., 0.92549],
[0.203922, 0., 0.929412],
[0.196078, 0., 0.933333],
[0.188235, 0., 0.933333],
[0.180392, 0., 0.937255],
[0.168627, 0., 0.941176],
[0.160784, 0., 0.945098],
[0.152941, 0., 0.945098],
[0.113725, 0., 0.760784],
[0.105882, 0., 0.760784],
[0.12549, 0., 0.956863],
[0.113725, 0., 0.960784],
[0.105882, 0., 0.960784],
[0.0980392, 0., 0.964706],
[0.0901961, 0., 0.968627],
[0.0784314, 0., 0.972549],
[0.0705882, 0., 0.972549],
[0.0627451, 0., 0.976471],
[0.0431373, 0., 0.784314],
[0.0352941, 0., 0.784314],
[0.0352941, 0., 0.984314],
[0.0235294, 0., 0.988235],
[0.0156863, 0., 0.992157],
[0.00784314, 0., 0.996078],
[0., 0., 1.],
[0., 0.0235294, 1.],
[0., 0.0470588, 1.],
[0., 0.0705882, 1.],
[0., 0.0745098, 0.8],
[0., 0.0941176, 0.8],
[0., 0.141176, 1.],
[0., 0.164706, 1.],
[0., 0.188235, 1.],
[0., 0.211765, 1.],
[0., 0.235294, 1.],
[0., 0.258824, 1.],
[0., 0.282353, 1.],
[0., 0.305882, 1.],
[0., 0.266667, 0.8],
[0., 0.282353, 0.8],
[0., 0.380392, 1.],
[0., 0.403922, 1.],
[0., 0.427451, 1.],
[0., 0.45098, 1.],
[0., 0.47451, 1.],
[0., 0.498039, 1.],
[0., 0.521569, 1.],
[0., 0.545098, 1.],
[0., 0.454902, 0.8],
[0., 0.47451, 0.8],
[0., 0.615686, 1.],
[0., 0.639216, 1.],
[0., 0.666667, 1.],
[0., 0.690196, 1.],
[0., 0.713725, 1.],
[0., 0.737255, 1.],
[0., 0.760784, 1.],
[0., 0.784314, 1.],
[0., 0.647059, 0.8],
[0., 0.666667, 0.8],
[0., 0.854902, 1.],
[0., 0.878431, 1.],
[0., 0.901961, 1.],
[0., 0.92549, 1.],
[0., 0.94902, 1.],
[0., 0.972549, 1.],
[0., 1., 1.],
[0., 1., 0.972549],
[0., 0.8, 0.760784],
[0., 0.8, 0.741176],
[0., 1., 0.901961],
[0., 1., 0.878431],
[0., 1., 0.854902],
[0., 1., 0.831373],
[0., 1., 0.807843],
[0., 1., 0.784314],
[0., 1., 0.760784],
[0., 1., 0.737255],
[0., 0.8, 0.568627],
[0., 0.8, 0.54902],
[0., 1., 0.662745],
[0., 1., 0.639216],
[0., 1., 0.615686],
[0., 1., 0.592157],
[0., 1., 0.568627],
[0., 1., 0.545098],
[0., 1., 0.521569],
[0., 1., 0.498039],
[0., 0.8, 0.380392],
[0., 0.8, 0.360784],
[0., 1., 0.427451],
[0., 1., 0.403922],
[0., 1., 0.380392],
[0., 1., 0.356863],
[0., 1., 0.329412],
[0., 1., 0.305882],
[0., 1., 0.282353],
[0., 1., 0.258824],
[0., 0.8, 0.188235],
[0., 0.8, 0.168627],
[0., 1., 0.188235],
[0., 1., 0.164706],
[0., 1., 0.141176],
[0., 1., 0.117647],
[0., 1., 0.0941176],
[0., 1., 0.0705882],
[0., 1., 0.0470588],
[0., 1., 0.0235294],
[0., 0.8, 0.],
[0.0156863, 0.8, 0.],
[0.0470588, 1., 0.],
[0.0705882, 1., 0.],
[0.0941176, 1., 0.],
[0.117647, 1., 0.],
[0.141176, 1., 0.],
[0.164706, 1., 0.],
[0.188235, 1., 0.],
[0.211765, 1., 0.],
[0.188235, 0.8, 0.],
[0.207843, 0.8, 0.],
[0.282353, 1., 0.],
[0.305882, 1., 0.],
[0.333333, 1., 0.],
[0.356863, 1., 0.],
[0.380392, 1., 0.],
[0.403922, 1., 0.],
[0.427451, 1., 0.],
[0.45098, 1., 0.],
[0.380392, 0.8, 0.],
[0.4, 0.8, 0.],
[0.521569, 1., 0.],
[0.545098, 1., 0.],
[0.568627, 1., 0.],
[0.592157, 1., 0.],
[0.615686, 1., 0.],
[0.639216, 1., 0.],
[0.666667, 1., 0.],
[0.690196, 1., 0.],
[0.568627, 0.8, 0.],
[0.588235, 0.8, 0.],
[0.760784, 1., 0.],
[0.784314, 1., 0.],
[0.807843, 1., 0.],
[0.831373, 1., 0.],
[0.854902, 1., 0.],
[0.878431, 1., 0.],
[0.901961, 1., 0.],
[0.92549, 1., 0.],
[0.760784, 0.8, 0.],
[0.780392, 0.8, 0.],
[1., 1., 0.],
[1., 0.972549, 0.00784314],
[1., 0.94902, 0.0196078],
[1., 0.921569, 0.027451],
[1., 0.898039, 0.0392157],
[1., 0.87451, 0.0470588],
[1., 0.847059, 0.0588235],
[1., 0.823529, 0.0666667],
[0.8, 0.639216, 0.0627451],
[0.8, 0.619608, 0.0705882],
[1., 0.74902, 0.0980392],
[1., 0.721569, 0.109804],
[1., 0.698039, 0.117647],
[1., 0.67451, 0.129412],
[1., 0.647059, 0.137255],
[1., 0.623529, 0.14902],
[1., 0.6, 0.156863],
[1., 0.572549, 0.168627],
[0.8, 0.439216, 0.141176],
[0.8, 0.419608, 0.14902],
[1., 0.498039, 0.2],
[1., 0.47451, 0.188235],
[1., 0.45098, 0.180392],
[1., 0.431373, 0.172549],
[1., 0.407843, 0.160784],
[1., 0.384314, 0.152941],
[1., 0.360784, 0.145098],
[1., 0.337255, 0.133333],
[0.8, 0.25098, 0.0980392],
[0.8, 0.235294, 0.0941176],
[1., 0.270588, 0.105882],
[1., 0.247059, 0.0980392],
[1., 0.223529, 0.0901961],
[1., 0.203922, 0.0784314],
[1., 0.180392, 0.0705882],
[1., 0.156863, 0.0627451],
[1., 0.133333, 0.0509804],
[1., 0.109804, 0.0431373],
[0.8, 0.0705882, 0.027451],
[0.8, 0.0509804, 0.0196078],
[1., 0.0431373, 0.0156863],
[1., 0.0196078, 0.00784314],
[1., 0., 0.],
[1., 0., 0.]]

test_cm = LinearSegmentedColormap.from_list(__file__, cm_data)


if __name__ == "__main__":
    import matplotlib.pyplot as plt
    import numpy as np

    try:
        from pycam02ucs.cm.viscm import viscm
        viscm(test_cm)
    except ImportError:
        print("pycam02ucs not found, falling back on simple display")
        plt.imshow(np.linspace(0, 100, 256)[None, :], aspect='auto',
                   cmap=test_cm)
    plt.show()