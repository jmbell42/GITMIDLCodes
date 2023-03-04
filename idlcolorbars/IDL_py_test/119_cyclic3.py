from matplotlib.colors import LinearSegmentedColormap
from numpy import nan, inf
cm_data = [[0.622204, 0.676707, 0.226828],
[0.619234, 0.67281, 0.234624],
[0.616276, 0.668917, 0.242099],
[0.61333, 0.66503, 0.249287],
[0.610395, 0.661148, 0.256206],
[0.60747, 0.657272, 0.262881],
[0.604557, 0.6534, 0.269323],
[0.601654, 0.649534, 0.275555],
[0.598762, 0.645673, 0.281585],
[0.59588, 0.641817, 0.287423],
[0.593008, 0.637965, 0.293085],
[0.590147, 0.63412, 0.298575],
[0.587296, 0.63028, 0.303907],
[0.584455, 0.626445, 0.309083],
[0.581622, 0.622614, 0.314113],
[0.5788, 0.61879, 0.319004],
[0.575988, 0.614971, 0.323758],
[0.573184, 0.611157, 0.328384],
[0.570389, 0.607347, 0.332882],
[0.567603, 0.603544, 0.337262],
[0.564827, 0.599746, 0.341523],
[0.562059, 0.595954, 0.345673],
[0.559298, 0.592166, 0.349712],
[0.556547, 0.588384, 0.353643],
[0.553803, 0.584608, 0.357471],
[0.551068, 0.580837, 0.361197],
[0.548339, 0.57707, 0.364825],
[0.54562, 0.573311, 0.368355],
[0.542907, 0.569557, 0.371792],
[0.540202, 0.565808, 0.375134],
[0.537503, 0.562064, 0.378387],
[0.534811, 0.558327, 0.381551],
[0.532127, 0.554596, 0.384626],
[0.529449, 0.550871, 0.387617],
[0.526777, 0.54715, 0.39052],
[0.524111, 0.543436, 0.393342],
[0.521452, 0.539729, 0.396079],
[0.518799, 0.536028, 0.398737],
[0.516149, 0.532331, 0.401312],
[0.513507, 0.528643, 0.403808],
[0.51087, 0.52496, 0.406224],
[0.508237, 0.521284, 0.408562],
[0.505609, 0.517614, 0.410821],
[0.502986, 0.513951, 0.413003],
[0.500367, 0.510295, 0.415107],
[0.497752, 0.506647, 0.417134],
[0.49514, 0.503004, 0.419082],
[0.492532, 0.49937, 0.420954],
[0.489927, 0.495744, 0.422747],
[0.487326, 0.492126, 0.424463],
[0.484725, 0.488515, 0.426098],
[0.482128, 0.484913, 0.427654],
[0.479533, 0.48132, 0.429128],
[0.476938, 0.477735, 0.430519],
[0.474344, 0.474161, 0.431826],
[0.471751, 0.470598, 0.433044],
[0.469157, 0.467046, 0.434172],
[0.466561, 0.463504, 0.435203],
[0.463964, 0.459977, 0.436134],
[0.461363, 0.456464, 0.436954],
[0.458756, 0.452969, 0.437652],
[0.456141, 0.449492, 0.438209],
[0.453514, 0.446041, 0.438594],
[0.450867, 0.442627, 0.438733],
[0.44964, 0.440797, 0.439614],
[0.452879, 0.443444, 0.444556],
[0.456151, 0.446056, 0.449746],
[0.459447, 0.448645, 0.455093],
[0.462764, 0.451218, 0.460565],
[0.466101, 0.453776, 0.466148],
[0.469455, 0.456319, 0.471831],
[0.472827, 0.458849, 0.477608],
[0.476217, 0.461367, 0.483476],
[0.479625, 0.463873, 0.489432],
[0.48305, 0.466365, 0.495472],
[0.486492, 0.468845, 0.501597],
[0.489951, 0.471312, 0.507805],
[0.493429, 0.473768, 0.514097],
[0.496925, 0.47621, 0.52047],
[0.500438, 0.478639, 0.526925],
[0.503969, 0.481055, 0.533463],
[0.50752, 0.483458, 0.540084],
[0.511089, 0.485846, 0.546787],
[0.514678, 0.48822, 0.553573],
[0.518285, 0.490579, 0.560444],
[0.521913, 0.492925, 0.5674],
[0.525561, 0.495254, 0.57444],
[0.529229, 0.497568, 0.581566],
[0.532918, 0.499865, 0.588779],
[0.536628, 0.502147, 0.596082],
[0.54036, 0.50441, 0.603472],
[0.544113, 0.506656, 0.610952],
[0.547889, 0.508883, 0.618523],
[0.551689, 0.511093, 0.626187],
[0.555511, 0.513282, 0.633943],
[0.559357, 0.515451, 0.641795],
[0.563227, 0.517599, 0.649743],
[0.567123, 0.519727, 0.657787],
[0.571043, 0.521832, 0.665931],
[0.574988, 0.523914, 0.674173],
[0.57896, 0.525973, 0.682518],
[0.582959, 0.528008, 0.690966],
[0.586985, 0.530017, 0.699518],
[0.591039, 0.531999, 0.708177],
[0.595122, 0.533956, 0.716943],
[0.599233, 0.535884, 0.725818],
[0.603374, 0.537782, 0.734804],
[0.607545, 0.539651, 0.743904],
[0.611748, 0.54149, 0.753118],
[0.615982, 0.543296, 0.762449],
[0.620248, 0.545068, 0.771899],
[0.624547, 0.546806, 0.781468],
[0.628881, 0.548509, 0.791161],
[0.633248, 0.550175, 0.800977],
[0.63765, 0.551801, 0.810921],
[0.642089, 0.553388, 0.820992],
[0.646565, 0.554935, 0.831197],
[0.651078, 0.556437, 0.841534],
[0.65563, 0.557896, 0.852005],
[0.660221, 0.559308, 0.862616],
[0.664853, 0.560673, 0.873366],
[0.669526, 0.561987, 0.88426],
[0.674241, 0.56325, 0.895298],
[0.678998, 0.564458, 0.906486],
[0.683802, 0.565612, 0.917825],
[0.688649, 0.566707, 0.929315],
[0.693542, 0.567741, 0.940964],
[0.698483, 0.568712, 0.95277],
[0.701842, 0.572048, 0.956342],
[0.703621, 0.577732, 0.951666],
[0.705453, 0.583337, 0.947131],
[0.707336, 0.588868, 0.942739],
[0.709271, 0.594329, 0.938483],
[0.711253, 0.599724, 0.934359],
[0.713282, 0.605055, 0.930368],
[0.715357, 0.610328, 0.926503],
[0.717477, 0.615546, 0.922765],
[0.719639, 0.62071, 0.919146],
[0.721844, 0.625824, 0.915649],
[0.724089, 0.630891, 0.912267],
[0.726375, 0.635914, 0.909],
[0.728699, 0.640894, 0.905846],
[0.731061, 0.645834, 0.902801],
[0.733459, 0.650735, 0.899865],
[0.735895, 0.655603, 0.897034],
[0.738364, 0.660434, 0.894308],
[0.740868, 0.665234, 0.891682],
[0.743406, 0.670003, 0.889156],
[0.745977, 0.674744, 0.886731],
[0.748579, 0.679456, 0.884401],
[0.751212, 0.684143, 0.882166],
[0.753876, 0.688805, 0.880024],
[0.756571, 0.693445, 0.877977],
[0.759295, 0.698061, 0.876017],
[0.762048, 0.702657, 0.874147],
[0.764829, 0.707233, 0.872367],
[0.767638, 0.711791, 0.870672],
[0.770474, 0.71633, 0.869063],
[0.773337, 0.720852, 0.867538],
[0.776227, 0.72536, 0.866098],
[0.779142, 0.729852, 0.864739],
[0.782083, 0.73433, 0.863461],
[0.785049, 0.738794, 0.862264],
[0.78804, 0.743247, 0.861148],
[0.791055, 0.747687, 0.86011],
[0.794095, 0.752115, 0.85915],
[0.797158, 0.756534, 0.858267],
[0.800245, 0.760943, 0.857463],
[0.803355, 0.765342, 0.856734],
[0.806488, 0.769733, 0.856081],
[0.809644, 0.774115, 0.855503],
[0.812823, 0.778491, 0.855003],
[0.816023, 0.782858, 0.854576],
[0.819246, 0.787219, 0.854224],
[0.822491, 0.791573, 0.853947],
[0.825758, 0.795922, 0.853746],
[0.829047, 0.800265, 0.85362],
[0.832357, 0.804603, 0.853569],
[0.835688, 0.808935, 0.853595],
[0.839043, 0.813264, 0.853698],
[0.842417, 0.817587, 0.853879],
[0.845814, 0.821905, 0.854139],
[0.849232, 0.826219, 0.854481],
[0.852673, 0.83053, 0.854907],
[0.856135, 0.834835, 0.855419],
[0.85962, 0.839135, 0.856022],
[0.863128, 0.84343, 0.856721],
[0.866661, 0.84772, 0.857526],
[0.870218, 0.852, 0.858446],
[0.873802, 0.85627, 0.859501],
[0.877418, 0.860525, 0.860729],
[0.88108, 0.864748, 0.862242],
[0.878788, 0.86323, 0.857553],
[0.874439, 0.85991, 0.8501],
[0.870072, 0.856639, 0.842383],
[0.865697, 0.853401, 0.834485],
[0.86132, 0.850194, 0.82645],
[0.856942, 0.847011, 0.818298],
[0.852567, 0.84385, 0.810044],
[0.848194, 0.840708, 0.801698],
[0.843827, 0.837585, 0.793269],
[0.839465, 0.83448, 0.784762],
[0.83511, 0.83139, 0.776182],
[0.83076, 0.828315, 0.767532],
[0.826419, 0.825255, 0.758817],
[0.822085, 0.822208, 0.750038],
[0.817759, 0.819173, 0.741197],
[0.813443, 0.816151, 0.732297],
[0.809136, 0.813141, 0.72334],
[0.804839, 0.810141, 0.714326],
[0.80055, 0.807151, 0.705256],
[0.796273, 0.804172, 0.696132],
[0.792006, 0.801201, 0.686954],
[0.78775, 0.79824, 0.677723],
[0.783504, 0.795286, 0.668439],
[0.779271, 0.792341, 0.659104],
[0.77505, 0.789403, 0.649716],
[0.77084, 0.786472, 0.640278],
[0.766642, 0.783547, 0.630786],
[0.762458, 0.780629, 0.621243],
[0.758286, 0.777717, 0.61165],
[0.754127, 0.77481, 0.602004],
[0.74998, 0.771907, 0.592306],
[0.745849, 0.76901, 0.582554],
[0.741731, 0.766117, 0.572752],
[0.737627, 0.763228, 0.562893],
[0.733537, 0.760341, 0.552979],
[0.729462, 0.757459, 0.543012],
[0.725402, 0.754579, 0.532987],
[0.721356, 0.751701, 0.522906],
[0.717326, 0.748825, 0.512762],
[0.713312, 0.745951, 0.50256],
[0.709313, 0.743079, 0.492294],
[0.705331, 0.740208, 0.481965],
[0.701364, 0.737336, 0.471566],
[0.697415, 0.734466, 0.461097],
[0.693482, 0.731596, 0.450558],
[0.689566, 0.728726, 0.439941],
[0.685666, 0.725855, 0.429244],
[0.681785, 0.722983, 0.418462],
[0.677921, 0.720111, 0.407593],
[0.674075, 0.717237, 0.396627],
[0.670246, 0.71436, 0.385559],
[0.666436, 0.711483, 0.374386],
[0.662645, 0.708603, 0.363094],
[0.658872, 0.705721, 0.351677],
[0.655118, 0.702835, 0.340121],
[0.651382, 0.699947, 0.328417],
[0.647667, 0.697056, 0.316546],
[0.643971, 0.694161, 0.304493],
[0.640292, 0.691262, 0.292238],
[0.636635, 0.68836, 0.279754],
[0.632997, 0.685453, 0.267014],
[0.62938, 0.682543, 0.253977],
[0.625781, 0.679627, 0.240601],
[0.622204, 0.676707, 0.226828]]

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