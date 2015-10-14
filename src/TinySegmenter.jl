module TinySegmenter

export Segmenter, tokenize

typealias US UTF8String

macro t_str(s)
  tuple(s...)
end

# Use out of range of Unicode code point. See also: https://en.wikipedia.org/wiki/Code_point
const B1 = Char(0x110001)
const B2 = Char(0x110002)
const B3 = Char(0x110003)
const E1 = Char(0x110004)
const E2 = Char(0x110005)
const E3 = Char(0x110006)

const BIAS = -332

const BC1 = Dict{Tuple{UInt8,UInt8},Int}(t"HH" => 6, t"II" => 2, t"OH" => -1378)
const BC2 = Dict{Tuple{UInt8,UInt8},Int}(t"AA" => -3267, t"AI" => 2744, t"AN" => -878, t"HH" => -4070, t"HM" => -1711, t"HN" => 4012, t"HO" => 3761, t"IA" => 1327, t"IH" => -1184, t"II" => -1332, t"IK" => 1721, t"IO" => 5492, t"KI" => 3831, t"KK" => -8741, t"MH" => -3132, t"MK" => 3334, t"OO" => -2920)
const BC3 = Dict{Tuple{UInt8,UInt8},Int}(t"HH" => 996, t"HI" => 626, t"HK" => -721, t"HN" => -1307, t"HO" => -836, t"IH" => -301, t"KK" => 2762, t"MK" => 1079, t"MM" => 4034, t"OA" => -1652, t"OH" => 266)
const BP1 = Dict{Tuple{UInt8,UInt8},Int}(t"BB" => 295, t"OB" => 304, t"OO" => -125, t"UB" => 352)
const BP2 = Dict{Tuple{UInt8,UInt8},Int}(t"BO" => 60, t"OO" => -1762)
const BQ1 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"BHH" => 1150, t"BHM" => 1521, t"BII" => -1158, t"BIM" => 886, t"BMH" => 1208, t"BNH" => 449, t"BOH" => -91, t"BOO" => -2597, t"OHI" => 451, t"OIH" => -296, t"OKA" => 1851, t"OKH" => -1020, t"OKK" => 904, t"OOO" => 2965)
const BQ2 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"BHH" => 118, t"BHI" => -1159, t"BHM" => 466, t"BIH" => -919, t"BKK" => -1720, t"BKO" => 864, t"OHH" => -1139, t"OHM" => -181, t"OIH" => 153, t"UHI" => -1146)
const BQ3 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"BHH" => -792, t"BHI" => 2664, t"BII" => -299, t"BKI" => 419, t"BMH" => 937, t"BMM" => 8335, t"BNN" => 998, t"BOH" => 775, t"OHH" => 2174, t"OHM" => 439, t"OII" => 280, t"OKH" => 1798, t"OKI" => -793, t"OKO" => -2242, t"OMH" => -2402, t"OOO" => 11699)
const BQ4 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"BHH" => -3895, t"BIH" => 3761, t"BII" => -4654, t"BIK" => 1348, t"BKK" => -1806, t"BMI" => -3385, t"BOO" => -12396, t"OAH" => 926, t"OHH" => 266, t"OHK" => -2036, t"ONN" => -973)
const BW1 = Dict{Tuple{Char,Char},Int}(t",と" => 660, t",同" => 727, (B1,'あ') => 1404, (B1,'同') => 542, t"、と" => 660, t"、同" => 727, t"」と" => 1682, t"あっ" => 1505, t"いう" => 1743, t"いっ" => -2055, t"いる" => 672, t"うし" => -4817, t"うん" => 665, t"から" => 3472, t"がら" => 600, t"こう" => -790, t"こと" => 2083, t"こん" => -1262, t"さら" => -4143, t"さん" => 4573, t"した" => 2641, t"して" => 1104, t"すで" => -3399, t"そこ" => 1977, t"それ" => -871, t"たち" => 1122, t"ため" => 601, t"った" => 3463, t"つい" => -802, t"てい" => 805, t"てき" => 1249, t"でき" => 1127, t"です" => 3445, t"では" => 844, t"とい" => -4915, t"とみ" => 1922, t"どこ" => 3887, t"ない" => 5713, t"なっ" => 3015, t"など" => 7379, t"なん" => -1113, t"にし" => 2468, t"には" => 1498, t"にも" => 1671, t"に対" => -912, t"の一" => -501, t"の中" => 741, t"ませ" => 2448, t"まで" => 1711, t"まま" => 2600, t"まる" => -2155, t"やむ" => -1947, t"よっ" => -2565, t"れた" => 2369, t"れで" => -913, t"をし" => 1860, t"を見" => 731, t"亡く" => -1886, t"京都" => 2558, t"取り" => -2784, t"大き" => -2604, t"大阪" => 1497, t"平方" => -2314, t"引き" => -1336, t"日本" => -195, t"本当" => -2423, t"毎日" => -2113, t"目指" => -724, (B1,'あ') => 1404, (B1,'同') => 542, t"｣と" => 1682)
const BW2 = Dict{Tuple{Char,Char},Int}(t".." => -11822, t"11" => -669, t"――" => -5730, t"−−" => -13175, t"いう" => -1609, t"うか" => 2490, t"かし" => -1350, t"かも" => -602, t"から" => -7194, t"かれ" => 4612, t"がい" => 853, t"がら" => -3198, t"きた" => 1941, t"くな" => -1597, t"こと" => -8392, t"この" => -4193, t"させ" => 4533, t"され" => 13168, t"さん" => -3977, t"しい" => -1819, t"しか" => -545, t"した" => 5078, t"して" => 972, t"しな" => 939, t"その" => -3744, t"たい" => -1253, t"たた" => -662, t"ただ" => -3857, t"たち" => -786, t"たと" => 1224, t"たは" => -939, t"った" => 4589, t"って" => 1647, t"っと" => -2094, t"てい" => 6144, t"てき" => 3640, t"てく" => 2551, t"ては" => -3110, t"ても" => -3065, t"でい" => 2666, t"でき" => -1528, t"でし" => -3828, t"です" => -4761, t"でも" => -4203, t"とい" => 1890, t"とこ" => -1746, t"とと" => -2279, t"との" => 720, t"とみ" => 5168, t"とも" => -3941, t"ない" => -2488, t"なが" => -1313, t"など" => -6509, t"なの" => 2614, t"なん" => 3099, t"にお" => -1615, t"にし" => 2748, t"にな" => 2454, t"によ" => -7236, t"に対" => -14943, t"に従" => -4688, t"に関" => -11388, t"のか" => 2093, t"ので" => -7059, t"のに" => -6041, t"のの" => -6125, t"はい" => 1073, t"はが" => -1033, t"はず" => -2532, t"ばれ" => 1813, t"まし" => -1316, t"まで" => -6621, t"まれ" => 5409, t"めて" => -3153, t"もい" => 2230, t"もの" => -10713, t"らか" => -944, t"らし" => -1611, t"らに" => -1897, t"りし" => 651, t"りま" => 1620, t"れた" => 4270, t"れて" => 849, t"れば" => 4114, t"ろう" => 6067, t"われ" => 7901, t"を通" => -11877, t"んだ" => 728, t"んな" => -4115, t"一人" => 602, t"一方" => -1375, t"一日" => 970, t"一部" => -1051, t"上が" => -4479, t"会社" => -1116, t"出て" => 2163, t"分の" => -7758, t"同党" => 970, t"同日" => -913, t"大阪" => -2471, t"委員" => -1250, t"少な" => -1050, t"年度" => -8669, t"年間" => -1626, t"府県" => -2363, t"手権" => -1982, t"新聞" => -4066, t"日新" => -722, t"日本" => -7068, t"日米" => 3372, t"曜日" => -601, t"朝鮮" => -2355, t"本人" => -2697, t"東京" => -1543, t"然と" => -1384, t"社会" => -1276, t"立て" => -990, t"第に" => -1612, t"米国" => -4268, t"１１" => -669)
const BW3 = Dict{Tuple{Char,Char},Int}(t"あた" => -2194, t"あり" => 719, t"ある" => 3846, t"い." => -1185, t"い。" => -1185, t"いい" => 5308, t"いえ" => 2079, t"いく" => 3029, t"いた" => 2056, t"いっ" => 1883, t"いる" => 5600, t"いわ" => 1527, t"うち" => 1117, t"うと" => 4798, t"えと" => 1454, t"か." => 2857, t"か。" => 2857, t"かけ" => -743, t"かっ" => -4098, t"かに" => -669, t"から" => 6520, t"かり" => -2670, t"が," => 1816, t"が、" => 1816, t"がき" => -4855, t"がけ" => -1127, t"がっ" => -913, t"がら" => -4977, t"がり" => -2064, t"きた" => 1645, t"けど" => 1374, t"こと" => 7397, t"この" => 1542, t"ころ" => -2757, t"さい" => -714, t"さを" => 976, t"し," => 1557, t"し、" => 1557, t"しい" => -3714, t"した" => 3562, t"して" => 1449, t"しな" => 2608, t"しま" => 1200, t"す." => -1310, t"す。" => -1310, t"する" => 6521, t"ず," => 3426, t"ず、" => 3426, t"ずに" => 841, t"そう" => 428, t"た." => 8875, t"た。" => 8875, t"たい" => -594, t"たの" => 812, t"たり" => -1183, t"たる" => -853, t"だ." => 4098, t"だ。" => 4098, t"だっ" => 1004, t"った" => -4748, t"って" => 300, t"てい" => 6240, t"てお" => 855, t"ても" => 302, t"です" => 1437, t"でに" => -1482, t"では" => 2295, t"とう" => -1387, t"とし" => 2266, t"との" => 541, t"とも" => -3543, t"どう" => 4664, t"ない" => 1796, t"なく" => -903, t"など" => 2135, t"に," => -1021, t"に、" => -1021, t"にし" => 1771, t"にな" => 1906, t"には" => 2644, t"の," => -724, t"の、" => -724, t"の子" => -1000, t"は," => 1337, t"は、" => 1337, t"べき" => 2181, t"まし" => 1113, t"ます" => 6943, t"まっ" => -1549, t"まで" => 6154, t"まれ" => -793, t"らし" => 1479, t"られ" => 6820, t"るる" => 3818, t"れ," => 854, t"れ、" => 854, t"れた" => 1850, t"れて" => 1375, t"れば" => -3246, t"れる" => 1091, t"われ" => -605, t"んだ" => 606, t"んで" => 798, t"カ月" => 990, t"会議" => 860, t"入り" => 1232, t"大会" => 2217, t"始め" => 1681, t"市 " => 965, t"新聞" => -5055, t"日," => 974, t"日、" => 974, t"社会" => 2024, t"ｶ月" => 990)
const TC1 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"AAA" => 1093, t"HHH" => 1029, t"HHM" => 580, t"HII" => 998, t"HOH" => -390, t"HOM" => -331, t"IHI" => 1169, t"IOH" => -142, t"IOI" => -1015, t"IOM" => 467, t"MMH" => 187, t"OOI" => -1832)
const TC2 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"HHO" => 2088, t"HII" => -1023, t"HMM" => -1154, t"IHI" => -1965, t"KKH" => 703, t"OII" => -2649)
const TC3 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"AAA" => -294, t"HHH" => 346, t"HHI" => -341, t"HII" => -1088, t"HIK" => 731, t"HOH" => -1486, t"IHH" => 128, t"IHI" => -3041, t"IHO" => -1935, t"IIH" => -825, t"IIM" => -1035, t"IOI" => -542, t"KHH" => -1216, t"KKA" => 491, t"KKH" => -1217, t"KOK" => -1009, t"MHH" => -2694, t"MHM" => -457, t"MHO" => 123, t"MMH" => -471, t"NNH" => -1689, t"NNO" => 662, t"OHO" => -3393)
const TC4 = Dict{Tuple{UInt8,UInt8,UInt8},Int}(t"HHH" => -203, t"HHI" => 1344, t"HHK" => 365, t"HHM" => -122, t"HHN" => 182, t"HHO" => 669, t"HIH" => 804, t"HII" => 679, t"HOH" => 446, t"IHH" => 695, t"IHO" => -2324, t"IIH" => 321, t"III" => 1497, t"IIO" => 656, t"IOO" => 54, t"KAK" => 4845, t"KKA" => 3386, t"KKK" => 3065, t"MHH" => -405, t"MHI" => 201, t"MMH" => -241, t"MMM" => 661, t"MOM" => 841)
const TQ1 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(t"BHHH" => -227, t"BHHI" => 316, t"BHIH" => -132, t"BIHH" => 60, t"BIII" => 1595, t"BNHH" => -744, t"BOHH" => 225, t"BOOO" => -908, t"OAKK" => 482, t"OHHH" => 281, t"OHIH" => 249, t"OIHI" => 200, t"OIIH" => -68)
const TQ2 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(t"BIHH" => -1401, t"BIII" => -1033, t"BKAK" => -543, t"BOOO" => -5591)
const TQ3 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(t"BHHH" => 478, t"BHHM" => -1073, t"BHIH" => 222, t"BHII" => -504, t"BIIH" => -116, t"BIII" => -105, t"BMHI" => -863, t"BMHM" => -464, t"BOMH" => 620, t"OHHH" => 346, t"OHHI" => 1729, t"OHII" => 997, t"OHMH" => 481, t"OIHH" => 623, t"OIIH" => 1344, t"OKAK" => 2792, t"OKHH" => 587, t"OKKA" => 679, t"OOHH" => 110, t"OOII" => -685)
const TQ4 = Dict{Tuple{UInt8,UInt8,UInt8,UInt8},Int}(t"BHHH" => -721, t"BHHM" => -3604, t"BHII" => -966, t"BIIH" => -607, t"BIII" => -2181, t"OAAA" => -2763, t"OAKK" => 180, t"OHHH" => -294, t"OHHI" => 2446, t"OHHO" => 480, t"OHIH" => -1573, t"OIHH" => 1935, t"OIHI" => -493, t"OIIH" => 626, t"OIII" => -4007, t"OKAK" => -8156)
const TW1 = Dict{Tuple{Char,Char,Char},Int}(t"につい" => -4681, t"東京都" => 2026)
const TW2 = Dict{Tuple{Char,Char,Char},Int}(t"ある程" => -2049, t"いった" => -1256, t"ころが" => -2434, t"しょう" => 3873, t"その後" => -4430, t"だって" => -1049, t"ていた" => 1833, t"として" => -4657, t"ともに" => -4517, t"もので" => 1882, t"一気に" => -792, t"初めて" => -1512, t"同時に" => -8097, t"大きな" => -1255, t"対して" => -2721, t"社会党" => -3216)
const TW3 = Dict{Tuple{Char,Char,Char},Int}(t"いただ" => -1734, t"してい" => 1314, t"として" => -4314, t"につい" => -5483, t"にとっ" => -5989, t"に当た" => -6247, t"ので," => -727, t"ので、" => -727, t"のもの" => -600, t"れから" => -3752, t"十二月" => -2287)
const TW4 = Dict{Tuple{Char,Char,Char},Int}(t"いう." => 8576, t"いう。" => 8576, t"からな" => -2348, t"してい" => 2958, t"たが," => 1516, t"たが、" => 1516, t"ている" => 1538, t"という" => 1349, t"ました" => 5543, t"ません" => 1097, t"ようと" => -4258, t"よると" => 5865)
const UC1 = Dict{UInt8,Int}('A' => 484, 'K' => 93, 'M' => 645, 'O' => -505)
const UC2 = Dict{UInt8,Int}('A' => 819, 'H' => 1059, 'I' => 409, 'M' => 3987, 'N' => 5775, 'O' => 646)
const UC3 = Dict{UInt8,Int}('A' => -1370, 'I' => 2311)
const UC4 = Dict{UInt8,Int}('A' => -2643, 'H' => 1809, 'I' => -1032, 'K' => -3450, 'M' => 3565, 'N' => 3876, 'O' => 6646)
const UC5 = Dict{UInt8,Int}('H' => 313, 'I' => -1238, 'K' => -799, 'M' => 539, 'O' => -831)
const UC6 = Dict{UInt8,Int}('H' => -506, 'I' => -253, 'K' => 87, 'M' => 247, 'O' => -387)
const UP1 = Dict{UInt8,Int}('O' => -214)
const UP2 = Dict{UInt8,Int}('B' => 69, 'O' => 935)
const UP3 = Dict{UInt8,Int}('B' => 189)
const UQ1 = Dict{Tuple{UInt8,UInt8},Int}(t"BH" => 21, t"BI" => -12, t"BK" => -99, t"BN" => 142, t"BO" => -56, t"OH" => -95, t"OI" => 477, t"OK" => 410, t"OO" => -2422)
const UQ2 = Dict{Tuple{UInt8,UInt8},Int}(t"BH" => 216, t"BI" => 113, t"OK" => 1759)
const UQ3 = Dict{Tuple{UInt8,UInt8},Int}(t"BA" => -479, t"BH" => 42, t"BI" => 1913, t"BK" => -7198, t"BM" => 3160, t"BN" => 6427, t"BO" => 14761, t"OI" => -827, t"ON" => -3212)
const UW1 = Dict{Char,Int}(',' => 156, '、' => 156, '「' => -463, 'あ' => -941, 'う' => -127, 'が' => -553, 'き' => 121, 'こ' => 505, 'で' => -201, 'と' => -547, 'ど' => -123, 'に' => -789, 'の' => -185, 'は' => -847, 'も' => -466, 'や' => -470, 'よ' => 182, 'ら' => -292, 'り' => 208, 'れ' => 169, 'を' => -446, 'ん' => -137, '・' => -135, '主' => -402, '京' => -268, '区' => -912, '午' => 871, '国' => -460, '大' => 561, '委' => 729, '市' => -411, '日' => -141, '理' => 361, '生' => -408, '県' => -386, '都' => -718, '｢' => -463, '･' => -135)
const UW2 = Dict{Char,Int}(',' => -829, '、' => -829, '〇' => 892, '「' => -645, '」' => 3145, 'あ' => -538, 'い' => 505, 'う' => 134, 'お' => -502, 'か' => 1454, 'が' => -856, 'く' => -412, 'こ' => 1141, 'さ' => 878, 'ざ' => 540, 'し' => 1529, 'す' => -675, 'せ' => 300, 'そ' => -1011, 'た' => 188, 'だ' => 1837, 'つ' => -949, 'て' => -291, 'で' => -268, 'と' => -981, 'ど' => 1273, 'な' => 1063, 'に' => -1764, 'の' => 130, 'は' => -409, 'ひ' => -1273, 'べ' => 1261, 'ま' => 600, 'も' => -1263, 'や' => -402, 'よ' => 1639, 'り' => -579, 'る' => -694, 'れ' => 571, 'を' => -2516, 'ん' => 2095, 'ア' => -587, 'カ' => 306, 'キ' => 568, 'ッ' => 831, '三' => -758, '不' => -2150, '世' => -302, '中' => -968, '主' => -861, '事' => 492, '人' => -123, '会' => 978, '保' => 362, '入' => 548, '初' => -3025, '副' => -1566, '北' => -3414, '区' => -422, '大' => -1769, '天' => -865, '太' => -483, '子' => -1519, '学' => 760, '実' => 1023, '小' => -2009, '市' => -813, '年' => -1060, '強' => 1067, '手' => -1519, '揺' => -1033, '政' => 1522, '文' => -1355, '新' => -1682, '日' => -1815, '明' => -1462, '最' => -630, '朝' => -1843, '本' => -1650, '東' => -931, '果' => -665, '次' => -2378, '民' => -180, '気' => -1740, '理' => 752, '発' => 529, '目' => -1584, '相' => -242, '県' => -1165, '立' => -763, '第' => 810, '米' => 509, '自' => -1353, '行' => 838, '西' => -744, '見' => -3874, '調' => 1010, '議' => 1198, '込' => 3041, '開' => 1758, '間' => -1257, '｢' => -645, '｣' => 3145, 'ｯ' => 831, 'ｱ' => -587, 'ｶ' => 306, 'ｷ' => 568)
const UW3 = Dict{Char,Int}(',' => 4889, '1' => -800, '−' => -1723, '、' => 4889, '々' => -2311, '〇' => 5827, '」' => 2670, '〓' => -3573, 'あ' => -2696, 'い' => 1006, 'う' => 2342, 'え' => 1983, 'お' => -4864, 'か' => -1163, 'が' => 3271, 'く' => 1004, 'け' => 388, 'げ' => 401, 'こ' => -3552, 'ご' => -3116, 'さ' => -1058, 'し' => -395, 'す' => 584, 'せ' => 3685, 'そ' => -5228, 'た' => 842, 'ち' => -521, 'っ' => -1444, 'つ' => -1081, 'て' => 6167, 'で' => 2318, 'と' => 1691, 'ど' => -899, 'な' => -2788, 'に' => 2745, 'の' => 4056, 'は' => 4555, 'ひ' => -2171, 'ふ' => -1798, 'へ' => 1199, 'ほ' => -5516, 'ま' => -4384, 'み' => -120, 'め' => 1205, 'も' => 2323, 'や' => -788, 'よ' => -202, 'ら' => 727, 'り' => 649, 'る' => 5905, 'れ' => 2773, 'わ' => -1207, 'を' => 6620, 'ん' => -518, 'ア' => 551, 'グ' => 1319, 'ス' => 874, 'ッ' => -1350, 'ト' => 521, 'ム' => 1109, 'ル' => 1591, 'ロ' => 2201, 'ン' => 278, '・' => -3794, '一' => -1619, '下' => -1759, '世' => -2087, '両' => 3815, '中' => 653, '主' => -758, '予' => -1193, '二' => 974, '人' => 2742, '今' => 792, '他' => 1889, '以' => -1368, '低' => 811, '何' => 4265, '作' => -361, '保' => -2439, '元' => 4858, '党' => 3593, '全' => 1574, '公' => -3030, '六' => 755, '共' => -1880, '円' => 5807, '再' => 3095, '分' => 457, '初' => 2475, '別' => 1129, '前' => 2286, '副' => 4437, '力' => 365, '動' => -949, '務' => -1872, '化' => 1327, '北' => -1038, '区' => 4646, '千' => -2309, '午' => -783, '協' => -1006, '口' => 483, '右' => 1233, '各' => 3588, '合' => -241, '同' => 3906, '和' => -837, '員' => 4513, '国' => 642, '型' => 1389, '場' => 1219, '外' => -241, '妻' => 2016, '学' => -1356, '安' => -423, '実' => -1008, '家' => 1078, '小' => -513, '少' => -3102, '州' => 1155, '市' => 3197, '平' => -1804, '年' => 2416, '広' => -1030, '府' => 1605, '度' => 1452, '建' => -2352, '当' => -3885, '得' => 1905, '思' => -1291, '性' => 1822, '戸' => -488, '指' => -3973, '政' => -2013, '教' => -1479, '数' => 3222, '文' => -1489, '新' => 1764, '日' => 2099, '旧' => 5792, '昨' => -661, '時' => -1248, '曜' => -951, '最' => -937, '月' => 4125, '期' => 360, '李' => 3094, '村' => 364, '東' => -805, '核' => 5156, '森' => 2438, '業' => 484, '氏' => 2613, '民' => -1694, '決' => -1073, '法' => 1868, '海' => -495, '無' => 979, '物' => 461, '特' => -3850, '生' => -273, '用' => 914, '町' => 1215, '的' => 7313, '直' => -1835, '省' => 792, '県' => 6293, '知' => -1528, '私' => 4231, '税' => 401, '立' => -960, '第' => 1201, '米' => 7767, '系' => 3066, '約' => 3663, '級' => 1384, '統' => -4229, '総' => 1163, '線' => 1255, '者' => 6457, '能' => 725, '自' => -2869, '英' => 785, '見' => 1044, '調' => -562, '財' => -733, '費' => 1777, '車' => 1835, '軍' => 1375, '込' => -1504, '通' => -1136, '選' => -681, '郎' => 1026, '郡' => 4404, '部' => 1200, '金' => 2163, '長' => 421, '開' => -1432, '間' => 1302, '関' => -1282, '雨' => 2009, '電' => -1045, '非' => 2066, '駅' => 1620, '１' => -800, '｣' => 2670, '･' => -3794, 'ｯ' => -1350, 'ｱ' => 551, 'ｸ' => 1319, 'ｽ' => 874, 'ﾄ' => 521, 'ﾑ' => 1109, 'ﾙ' => 1591, 'ﾛ' => 2201, 'ﾝ' => 278)
const UW4 = Dict{Char,Int}(',' => 3930, '.' => 3508, '―' => -4841, '、' => 3930, '。' => 3508, '〇' => 4999, '「' => 1895, '」' => 3798, '〓' => -5156, 'あ' => 4752, 'い' => -3435, 'う' => -640, 'え' => -2514, 'お' => 2405, 'か' => 530, 'が' => 6006, 'き' => -4482, 'ぎ' => -3821, 'く' => -3788, 'け' => -4376, 'げ' => -4734, 'こ' => 2255, 'ご' => 1979, 'さ' => 2864, 'し' => -843, 'じ' => -2506, 'す' => -731, 'ず' => 1251, 'せ' => 181, 'そ' => 4091, 'た' => 5034, 'だ' => 5408, 'ち' => -3654, 'っ' => -5882, 'つ' => -1659, 'て' => 3994, 'で' => 7410, 'と' => 4547, 'な' => 5433, 'に' => 6499, 'ぬ' => 1853, 'ね' => 1413, 'の' => 7396, 'は' => 8578, 'ば' => 1940, 'ひ' => 4249, 'び' => -4134, 'ふ' => 1345, 'へ' => 6665, 'べ' => -744, 'ほ' => 1464, 'ま' => 1051, 'み' => -2082, 'む' => -882, 'め' => -5046, 'も' => 4169, 'ゃ' => -2666, 'や' => 2795, 'ょ' => -1544, 'よ' => 3351, 'ら' => -2922, 'り' => -9726, 'る' => -14896, 'れ' => -2613, 'ろ' => -4570, 'わ' => -1783, 'を' => 13150, 'ん' => -2352, 'カ' => 2145, 'コ' => 1789, 'セ' => 1287, 'ッ' => -724, 'ト' => -403, 'メ' => -1635, 'ラ' => -881, 'リ' => -541, 'ル' => -856, 'ン' => -3637, '・' => -4371, 'ー' => -11870, '一' => -2069, '中' => 2210, '予' => 782, '事' => -190, '井' => -1768, '人' => 1036, '以' => 544, '会' => 950, '体' => -1286, '作' => 530, '側' => 4292, '先' => 601, '党' => -2006, '共' => -1212, '内' => 584, '円' => 788, '初' => 1347, '前' => 1623, '副' => 3879, '力' => -302, '動' => -740, '務' => -2715, '化' => 776, '区' => 4517, '協' => 1013, '参' => 1555, '合' => -1834, '和' => -681, '員' => -910, '器' => -851, '回' => 1500, '国' => -619, '園' => -1200, '地' => 866, '場' => -1410, '塁' => -2094, '士' => -1413, '多' => 1067, '大' => 571, '子' => -4802, '学' => -1397, '定' => -1057, '寺' => -809, '小' => 1910, '屋' => -1328, '山' => -1500, '島' => -2056, '川' => -2667, '市' => 2771, '年' => 374, '庁' => -4556, '後' => 456, '性' => 553, '感' => 916, '所' => -1566, '支' => 856, '改' => 787, '政' => 2182, '教' => 704, '文' => 522, '方' => -856, '日' => 1798, '時' => 1829, '最' => 845, '月' => -9066, '木' => -485, '来' => -442, '校' => -360, '業' => -1043, '氏' => 5388, '民' => -2716, '気' => -910, '沢' => -939, '済' => -543, '物' => -735, '率' => 672, '球' => -1267, '生' => -1286, '産' => -1101, '田' => -2900, '町' => 1826, '的' => 2586, '目' => 922, '省' => -3485, '県' => 2997, '空' => -867, '立' => -2112, '第' => 788, '米' => 2937, '系' => 786, '約' => 2171, '経' => 1146, '統' => -1169, '総' => 940, '線' => -994, '署' => 749, '者' => 2145, '能' => -730, '般' => -852, '行' => -792, '規' => 792, '警' => -1184, '議' => -244, '谷' => -1000, '賞' => 730, '車' => -1481, '軍' => 1158, '輪' => -1433, '込' => -3370, '近' => 929, '道' => -1291, '選' => 2596, '郎' => -4866, '都' => 1192, '野' => -1100, '銀' => -2213, '長' => 357, '間' => -2344, '院' => -2297, '際' => -2604, '電' => -878, '領' => -1659, '題' => -792, '館' => -1984, '首' => 1749, '高' => 2120, '｢' => 1895, '｣' => 3798, '･' => -4371, 'ｯ' => -724, 'ｰ' => -11870, 'ｶ' => 2145, 'ｺ' => 1789, 'ｾ' => 1287, 'ﾄ' => -403, 'ﾒ' => -1635, 'ﾗ' => -881, 'ﾘ' => -541, 'ﾙ' => -856, 'ﾝ' => -3637)
const UW5 = Dict{Char,Int}(',' => 465, '.' => -299, '1' => -514, E2 => -32768, ']' => -2762, '、' => 465, '。' => -299, '「' => 363, 'あ' => 1655, 'い' => 331, 'う' => -503, 'え' => 1199, 'お' => 527, 'か' => 647, 'が' => -421, 'き' => 1624, 'ぎ' => 1971, 'く' => 312, 'げ' => -983, 'さ' => -1537, 'し' => -1371, 'す' => -852, 'だ' => -1186, 'ち' => 1093, 'っ' => 52, 'つ' => 921, 'て' => -18, 'で' => -850, 'と' => -127, 'ど' => 1682, 'な' => -787, 'に' => -1224, 'の' => -635, 'は' => -578, 'べ' => 1001, 'み' => 502, 'め' => 865, 'ゃ' => 3350, 'ょ' => 854, 'り' => -208, 'る' => 429, 'れ' => 504, 'わ' => 419, 'を' => -1264, 'ん' => 327, 'イ' => 241, 'ル' => 451, 'ン' => -343, '中' => -871, '京' => 722, '会' => -1153, '党' => -654, '務' => 3519, '区' => -901, '告' => 848, '員' => 2104, '大' => -1296, '学' => -548, '定' => 1785, '嵐' => -1304, '市' => -2991, '席' => 921, '年' => 1763, '思' => 872, '所' => -814, '挙' => 1618, '新' => -1682, '日' => 218, '月' => -4353, '査' => 932, '格' => 1356, '機' => -1508, '氏' => -1347, '田' => 240, '町' => -3912, '的' => -3149, '相' => 1319, '省' => -1052, '県' => -4003, '研' => -997, '社' => -278, '空' => -813, '統' => 1955, '者' => -2233, '表' => 663, '語' => -1073, '議' => 1219, '選' => -1018, '郎' => -368, '長' => 786, '間' => 1191, '題' => 2368, '館' => -689, '１' => -514, E2 => -32768, '｢' => 363, 'ｲ' => 241, 'ﾙ' => 451, 'ﾝ' => -343)
const UW6 = Dict{Char,Int}(',' => 227, '.' => 808, '1' => -270, E1 => 306, '、' => 227, '。' => 808, 'あ' => -307, 'う' => 189, 'か' => 241, 'が' => -73, 'く' => -121, 'こ' => -200, 'じ' => 1782, 'す' => 383, 'た' => -428, 'っ' => 573, 'て' => -1014, 'で' => 101, 'と' => -105, 'な' => -253, 'に' => -149, 'の' => -417, 'は' => -236, 'も' => -206, 'り' => 187, 'る' => -135, 'を' => 195, 'ル' => -673, 'ン' => -496, '一' => -277, '中' => 201, '件' => -800, '会' => 624, '前' => 302, '区' => 1792, '員' => -1212, '委' => 798, '学' => -960, '市' => 887, '広' => -695, '後' => 535, '業' => -697, '相' => 753, '社' => -507, '福' => 974, '空' => -822, '者' => 1811, '連' => 463, '郎' => 1082, '１' => -270, E1 => 306, 'ﾙ' => -673, 'ﾝ' => -496)

const CHARDICT = Dict{Char, UInt8}()
for (chars,cat) in (
    ("一二三四五六七八九十百千万億兆",'M'),
    ("々〆ヵヶ", 'H'),
    ('ぁ':'ん','I'),
    ('ァ':'ヴ','K'),
    ("ーｰ\uff9e",'K'),
    ('ｱ':'ﾝ','K'),
    (['a':'z';'A':'Z';'ａ':'ｚ';'Ａ':'Ｚ'],'A'),
    (['0':'9';'０':'９'],'N')
  )
  for c in chars
      CHARDICT[c] = cat
  end
end
const Achar = UInt8('A')
const Ichar = UInt8('I')
const Hchar = UInt8('H')
const Ochar = UInt8('O')
const Uchar = UInt8('U')
const Bchar = UInt8('B')
function _ctype(c::Char)
  return get(CHARDICT, c, '一' <= c <= '龠' ? Hchar : Ochar)
end

function tokenize(text::AbstractString)
  if isempty(text)
    return US[]
  end

  result = US[]
  segment = [B3, B2, B1]
  ctype = UInt8['O', 'O', 'O']
  for char in text
    push!(segment, char)
    push!(ctype, _ctype(char))
  end

  segment = vcat(segment, [E1, E2, E3])
  ctype = vcat(ctype, UInt8['O', 'O', 'O'])

  word = IOBuffer()
  print(word, segment[4])
  p1 = Uchar
  p2 = Uchar
  p3 = Uchar
  for i in 5:(length(segment)-3)
    score = BIAS
    w1 = segment[i-3]
    w2 = segment[i-2]
    w3 = segment[i-1]
    w4 = segment[i]
    w5 = segment[i+1]
    w6 = segment[i+2]
    c1 = ctype[i-3]
    c2 = ctype[i-2]
    c3 = ctype[i-1]
    c4 = ctype[i]
    c5 = ctype[i+1]
    c6 = ctype[i+2]

    if p1 == Ochar; score += -214; end # score += get(UP1, p1, 0)
    if p2 == Bchar; score += 69; elseif p2 == Ochar; score += 935; end # score += get(UP2, p2, 0)
    if p3 == Bchar; score += 189; end # score += get(UP3, p3, 0)
    score += get(BP1, (p1, p2), 0)
    score += get(BP2, (p2, p3), 0)
    score += get(UW1, w1, 0)
    score += get(UW2, w2, 0)
    score += get(UW3, w3, 0)
    score += get(UW4, w4, 0)
    score += get(UW5, w5, 0)
    score += get(UW6, w6, 0)
    score += get(BW1, (w2, w3), 0)
    score += get(BW2, (w3, w4), 0)
    score += get(BW3, (w4, w5), 0)
    score += get(TW1, (w1, w2, w3), 0)
    score += get(TW2, (w2, w3, w4), 0)
    score += get(TW3, (w3, w4, w5), 0)
    score += get(TW4, (w4, w5, w6), 0)
    score += get(UC1, c1, 0)
    score += get(UC2, c2, 0)
    if c3 == Achar; score += -1370; elseif c3 == Ichar; score += 2311; end # score += get(UC3, c3, 0)
    score += get(UC4, c4, 0)
    score += get(UC5, c5, 0)
    score += get(UC6, c6, 0)
    score += get(BC1, (c2, c3), 0)
    score += get(BC2, (c3, c4), 0)
    score += get(BC3, (c4, c5), 0)
    score += get(UQ1, (p1, c1), 0)
    score += get(UQ2, (p2, c2), 0)
    score += get(UQ3, (p3, c3), 0)
    score += get(BQ1, (p2, c2, c3), 0)
    score += get(BQ2, (p2, c3, c4), 0)
    score += get(BQ3, (p3, c2, c3), 0)
    score += get(BQ4, (p3, c3, c4), 0)
    score += get(TQ1, (p2, c1, c2, c3), 0)
    score += get(TQ2, (p2, c2, c3, c4), 0)
    score += get(TQ3, (p3, c1, c2, c3), 0)
    score += get(TQ4, (p3, c2, c3, c4), 0)
    p = Ochar
    if score > 0
      push!(result, takebuf_string(word))
      p = Bchar
    end

    p1 = p2
    p2 = p3
    p3 = p
    print(word, segment[i])
  end

  push!(result, takebuf_string(word))
  return result
end

end # module
