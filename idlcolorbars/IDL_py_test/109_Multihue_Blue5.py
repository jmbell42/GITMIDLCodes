from matplotlib.colors import LinearSegmentedColormap
from numpy import nan, inf
cm_data = [[0.0000208612, 0.0000200049, 0.0000198463],
[0.000412981, 0.000323037, 0.00038432],
[0.00122275, 0.000905571, 0.00113817],
[0.00242015, 0.00172559, 0.0022602],
[0.00399242, 0.00276029, 0.0037473],
[0.00593206, 0.00399435, 0.00560291],
[0.00823391, 0.00541645, 0.00783402],
[0.010894, 0.00701782, 0.0104499],
[0.0139089, 0.00879144, 0.0134617],
[0.0172755, 0.0107316, 0.0168816],
[0.0209908, 0.0128336, 0.0207233],
[0.0250517, 0.0150935, 0.025001],
[0.029455, 0.0175082, 0.0297303],
[0.0341972, 0.0200748, 0.0349271],
[0.0392749, 0.0227913, 0.0406055],
[0.0444925, 0.0256559, 0.0464214],
[0.0496278, 0.0286673, 0.0522398],
[0.0546942, 0.0318245, 0.0580658],
[0.0596949, 0.0351268, 0.0639035],
[0.0646322, 0.0385739, 0.0697566],
[0.0695084, 0.0421165, 0.0756283],
[0.0743252, 0.0456139, 0.0815212],
[0.079084, 0.0490757, 0.0874378],
[0.083786, 0.0525051, 0.0933802],
[0.0884321, 0.0559052, 0.0993501],
[0.0930231, 0.0592787, 0.105349],
[0.0975596, 0.0626283, 0.111378],
[0.102042, 0.0659565, 0.117439],
[0.106471, 0.0692655, 0.123532],
[0.110845, 0.0725577, 0.129659],
[0.115167, 0.075835, 0.135819],
[0.119434, 0.0790995, 0.142013],
[0.123648, 0.0823531, 0.148241],
[0.127809, 0.0855976, 0.154504],
[0.131914, 0.0888348, 0.160802],
[0.135966, 0.0920664, 0.167134],
[0.139962, 0.095294, 0.1735],
[0.143903, 0.0985193, 0.1799],
[0.147788, 0.101744, 0.186334],
[0.151617, 0.104969, 0.1928],
[0.155388, 0.108196, 0.199299],
[0.159102, 0.111427, 0.205829],
[0.162757, 0.114663, 0.21239],
[0.166353, 0.117905, 0.218981],
[0.169889, 0.121155, 0.2256],
[0.173364, 0.124413, 0.232247],
[0.176778, 0.127682, 0.23892],
[0.18013, 0.130963, 0.245618],
[0.183418, 0.134256, 0.252339],
[0.186642, 0.137563, 0.259083],
[0.189801, 0.140885, 0.265847],
[0.192894, 0.144223, 0.27263],
[0.19592, 0.147578, 0.27943],
[0.198877, 0.150952, 0.286246],
[0.201766, 0.154345, 0.293075],
[0.204585, 0.157758, 0.299916],
[0.207333, 0.161193, 0.306767],
[0.210009, 0.164651, 0.313626],
[0.212612, 0.168131, 0.32049],
[0.21514, 0.171636, 0.327357],
[0.217594, 0.175165, 0.334225],
[0.219971, 0.178721, 0.341093],
[0.222271, 0.182303, 0.347956],
[0.224492, 0.185913, 0.354814],
[0.226634, 0.189551, 0.361664],
[0.228696, 0.193217, 0.368503],
[0.230676, 0.196913, 0.375328],
[0.232574, 0.200639, 0.382138],
[0.234388, 0.204396, 0.38893],
[0.236118, 0.208183, 0.3957],
[0.237762, 0.212003, 0.402447],
[0.239319, 0.215854, 0.409168],
[0.240789, 0.219738, 0.41586],
[0.242171, 0.223654, 0.422521],
[0.243464, 0.227603, 0.429147],
[0.244666, 0.231585, 0.435737],
[0.245777, 0.235601, 0.442287],
[0.246797, 0.23965, 0.448795],
[0.247724, 0.243733, 0.455258],
[0.248558, 0.247849, 0.461673],
[0.249298, 0.251999, 0.468039],
[0.249943, 0.256182, 0.474352],
[0.250493, 0.260399, 0.48061],
[0.250947, 0.264649, 0.48681],
[0.251306, 0.268931, 0.492951],
[0.251568, 0.273246, 0.499028],
[0.251733, 0.277594, 0.50504],
[0.251801, 0.281973, 0.510986],
[0.251772, 0.286384, 0.516861],
[0.251646, 0.290825, 0.522665],
[0.251423, 0.295297, 0.528394],
[0.251103, 0.299799, 0.534047],
[0.250686, 0.304329, 0.539622],
[0.250172, 0.308889, 0.545117],
[0.249563, 0.313476, 0.55053],
[0.248858, 0.31809, 0.555859],
[0.248059, 0.32273, 0.561103],
[0.247166, 0.327396, 0.566259],
[0.246181, 0.332086, 0.571326],
[0.245104, 0.336799, 0.576303],
[0.243937, 0.341536, 0.581189],
[0.242682, 0.346293, 0.585982],
[0.24134, 0.351072, 0.590681],
[0.239914, 0.35587, 0.595285],
[0.238405, 0.360687, 0.599792],
[0.236817, 0.365521, 0.604203],
[0.235152, 0.370372, 0.608517],
[0.233413, 0.375238, 0.612732],
[0.231604, 0.380118, 0.616848],
[0.229728, 0.385011, 0.620865],
[0.22779, 0.389916, 0.624783],
[0.225793, 0.394832, 0.628601],
[0.223743, 0.399758, 0.632319],
[0.221645, 0.404691, 0.635937],
[0.219505, 0.409633, 0.639456],
[0.217328, 0.41458, 0.642875],
[0.215123, 0.419532, 0.646195],
[0.212896, 0.424488, 0.649416],
[0.210654, 0.429446, 0.652539],
[0.208407, 0.434406, 0.655564],
[0.206164, 0.439366, 0.658493],
[0.203934, 0.444326, 0.661326],
[0.201728, 0.449283, 0.664063],
[0.199557, 0.454238, 0.666707],
[0.197433, 0.459188, 0.669258],
[0.195368, 0.464133, 0.671717],
[0.193375, 0.469073, 0.674086],
[0.191469, 0.474005, 0.676365],
[0.189664, 0.478928, 0.678558],
[0.187975, 0.483843, 0.680664],
[0.186417, 0.488747, 0.682686],
[0.185006, 0.493641, 0.684626],
[0.183758, 0.498523, 0.686484],
[0.182689, 0.503392, 0.688264],
[0.181816, 0.508247, 0.689967],
[0.181153, 0.513088, 0.691595],
[0.180717, 0.517914, 0.693149],
[0.180521, 0.522724, 0.694633],
[0.180579, 0.527517, 0.696048],
[0.180903, 0.532293, 0.697397],
[0.181505, 0.537051, 0.698681],
[0.182393, 0.541791, 0.699903],
[0.183577, 0.546511, 0.701065],
[0.18506, 0.551212, 0.702171],
[0.186849, 0.555892, 0.703221],
[0.188944, 0.560552, 0.704219],
[0.191346, 0.565191, 0.705168],
[0.194054, 0.569809, 0.706068],
[0.197064, 0.574404, 0.706924],
[0.200372, 0.578977, 0.707738],
[0.203971, 0.583528, 0.708512],
[0.207854, 0.588056, 0.709248],
[0.212013, 0.592561, 0.709951],
[0.216439, 0.597042, 0.710621],
[0.221121, 0.6015, 0.711262],
[0.22605, 0.605935, 0.711876],
[0.231213, 0.610345, 0.712467],
[0.236602, 0.614732, 0.713036],
[0.242205, 0.619095, 0.713586],
[0.24801, 0.623434, 0.714121],
[0.254008, 0.627748, 0.714642],
[0.260188, 0.632039, 0.715152],
[0.266539, 0.636306, 0.715654],
[0.273052, 0.640549, 0.71615],
[0.279718, 0.644769, 0.716644],
[0.286528, 0.648965, 0.717137],
[0.293472, 0.653137, 0.717632],
[0.300542, 0.657286, 0.718132],
[0.307732, 0.661412, 0.71864],
[0.315032, 0.665515, 0.719157],
[0.322437, 0.669595, 0.719687],
[0.329939, 0.673654, 0.720232],
[0.337532, 0.67769, 0.720793],
[0.345211, 0.681704, 0.721375],
[0.352969, 0.685697, 0.721979],
[0.360801, 0.689669, 0.722607],
[0.368702, 0.69362, 0.723262],
[0.376667, 0.69755, 0.723947],
[0.384693, 0.701461, 0.724663],
[0.392773, 0.705353, 0.725413],
[0.400906, 0.709225, 0.726198],
[0.409086, 0.713079, 0.727022],
[0.41731, 0.716914, 0.727887],
[0.425575, 0.720732, 0.728794],
[0.433877, 0.724533, 0.729745],
[0.442214, 0.728318, 0.730743],
[0.450583, 0.732086, 0.73179],
[0.45898, 0.735838, 0.732888],
[0.467403, 0.739576, 0.734038],
[0.47585, 0.743299, 0.735243],
[0.484318, 0.747009, 0.736504],
[0.492805, 0.750705, 0.737823],
[0.501309, 0.754389, 0.739203],
[0.509827, 0.75806, 0.740644],
[0.518358, 0.76172, 0.742149],
[0.526901, 0.76537, 0.743719],
[0.535452, 0.769009, 0.745356],
[0.54401, 0.772639, 0.747061],
[0.552574, 0.77626, 0.748837],
[0.561143, 0.779873, 0.750683],
[0.569713, 0.783479, 0.752603],
[0.578285, 0.787078, 0.754597],
[0.586856, 0.790671, 0.756666],
[0.595426, 0.794258, 0.758813],
[0.603992, 0.797841, 0.761037],
[0.612554, 0.801421, 0.763341],
[0.621111, 0.804997, 0.765726],
[0.62966, 0.80857, 0.768193],
[0.638202, 0.812142, 0.770742],
[0.646734, 0.815713, 0.773376],
[0.655257, 0.819284, 0.776094],
[0.663768, 0.822855, 0.778898],
[0.672266, 0.826428, 0.781788],
[0.680751, 0.830003, 0.784766],
[0.689222, 0.833581, 0.787833],
[0.697678, 0.837163, 0.790988],
[0.706117, 0.840749, 0.794234],
[0.714539, 0.844341, 0.797569],
[0.722943, 0.847939, 0.800996],
[0.731329, 0.851543, 0.804513],
[0.739694, 0.855156, 0.808123],
[0.748038, 0.858777, 0.811825],
[0.756361, 0.862408, 0.81562],
[0.764662, 0.866048, 0.819508],
[0.772939, 0.869701, 0.823489],
[0.781192, 0.873365, 0.827564],
[0.78942, 0.877042, 0.831732],
[0.797623, 0.880732, 0.835994],
[0.805799, 0.884437, 0.840349],
[0.813948, 0.888158, 0.844798],
[0.822068, 0.891895, 0.849341],
[0.83016, 0.89565, 0.853977],
[0.838222, 0.899423, 0.858706],
[0.846253, 0.903215, 0.863527],
[0.854253, 0.907027, 0.868441],
[0.86222, 0.91086, 0.873447],
[0.870155, 0.914715, 0.878544],
[0.878055, 0.918593, 0.883731],
[0.88592, 0.922495, 0.889008],
[0.893749, 0.926423, 0.894375],
[0.901542, 0.930377, 0.899829],
[0.909296, 0.934358, 0.905369],
[0.91701, 0.938368, 0.910996],
[0.924685, 0.942407, 0.916706],
[0.932317, 0.946478, 0.922499],
[0.939905, 0.950581, 0.928372],
[0.947449, 0.954718, 0.934323],
[0.954945, 0.958891, 0.94035],
[0.96239, 0.963102, 0.946449],
[0.969783, 0.967352, 0.952617],
[0.977118, 0.971645, 0.958849],
[0.984391, 0.975985, 0.965138],
[0.991592, 0.980375, 0.971477],
[0.998709, 0.984824, 0.977851],
[1., 0.989346, 0.984234],
[1., 0.994001, 0.990529]]

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