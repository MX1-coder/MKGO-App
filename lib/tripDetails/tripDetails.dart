// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// import 'package:latlng/latlng.dart';
import 'package:mkgo_mobile/cart/cart.dart';
import 'package:mkgo_mobile/homeScreen/homeScreen.dart';
import 'package:mkgo_mobile/tripDetails/route.dart';
// import 'package:mkgo_mobile/tripDetails/tripLocation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

var pdfUrl =
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
var pdfFileName = pdfUrl.split('/').last;

class TripDetails extends StatefulWidget {
  const TripDetails({super.key});

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  String id = Get.arguments[0].toString();

  bool isRefreshed = false;

  late GoogleMapController _controller;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    setState(() {
      isRefreshed = true;
    });

    tripDetails();
    getDetails();
    _addMarkers();
    _calculateDistance();
    // _generateRouteCoordinates();
  }

  String nom = "";
  String prenom = "";

  Future<void> getDetails() async {
    final box = GetStorage();
    final _token = box.read('token') ?? '';
    print("token called: $_token");

    final storage = GetStorage();
    final UserID = storage.read('user_id');

    final configData = await rootBundle.loadString('assets/config/config.json');
    final configJson = json.decode(configData);

    final gestionBaseUrl = configJson['gestion_baseUrl'];
    final gestionApiKey = configJson['gestion_apiKey'];

    final gestionMainUrl =
        gestionBaseUrl + "mob/one-employe/" + UserID.toString();

    var headers = {
      'x-api-key': '$gestionApiKey',
      'Authorization': 'Bearer ' + _token
    };
    var request = http.Request('GET', Uri.parse(gestionMainUrl));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final apiData = jsonDecode(responseBody);

      String name2 = apiData['nom'];
      String surname2 = apiData['prenom'];
      setState(() {
        nom = name2;
        prenom = surname2;
      });
      setState(() {
        isRefreshed = false;
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  List<dynamic> mainTripDetails = [];
  String comment = "";
  String payment = "";
  String referenceNumber = "";
  String? address1;
  String? address2;
  String? file1;
  String? file2;
  String? telephoneNumber;
  String distance = '';
  String time = '';

  Future<List<Map<String, String>>> tripDetails() async {
    final box = GetStorage();
    final _token = box.read('token') ?? '';

    final configData = await rootBundle.loadString('assets/config/config.json');
    final configJson = json.decode(configData);

    final gestionBaseUrl = configJson['planning_baseUrl'];
    final gestionApiKey = configJson['planning_apiKey'];

    final gestionMainUrl =
        gestionBaseUrl + "mob/detailscourse/" + id.toString();

    var headers = {
      'x-api-key': '$gestionApiKey',
      'Authorization': 'Bearer ' + _token
    };

    var request = http.Request('GET', Uri.parse(gestionMainUrl));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final apiData = jsonDecode(responseBody);

      // print(apiData);

      setState(() {
        referenceNumber = apiData['reference'];
        comment = apiData['commentaire'];
        payment = apiData['paiement'];
        address1 = apiData['depart'];
        address2 = apiData['arrive'];
        file1 = apiData['filename1'];
        file2 = apiData['filename2'];
        telephoneNumber = apiData['clientDetails']['tel1'];
        distance = apiData['distanceTrajet'];
        time = apiData['dureeTrajet'];
      });

      List<Map<String, String>> tripDetailsList = [];

      int id = apiData['id'];
      int nombrePassager = apiData['nombrePassager'];
      String commentaire = apiData['commentaire'];
      String paiement = apiData['paiement'];
      int client = apiData['client'];
      String reference = apiData['reference'];
      String status1 = apiData['affectationCourses'][0]['status1'];
      String status2 = apiData['affectationCourses'][0]['status2'];
      String backgroundColor = apiData['backgroundColor'];
      String dateCourse = apiData['dateCourse'];
      String distanceTrajet = apiData['distanceTrajet'];
      String dureeTrajet = apiData['dureeTrajet'];
      String nom = apiData['clientDetails']['nom'];
      String prenom = apiData['clientDetails']['prenom'];
      String telephone = apiData['clientDetails']['tel1'];
      String depart = apiData['depart'] ?? '';
      String arrive = apiData['arrive'] ?? '';
      int imgType = apiData['clientDetails']['typeClient']['id'] ?? "";

      // Create a map with the extracted values
      Map<String, String> tripDetails = {
        'id': id.toString(),
        'nombrePassager': nombrePassager.toString(),
        'commentaire': commentaire,
        'paiement': paiement,
        'client': client.toString(),
        'refernce': reference,
        'status1': status1,
        'status2': status2,
        'backgroundColor': backgroundColor,
        'dateCourse': dateCourse,
        'distanceTrajet': distanceTrajet,
        'dureeTrajet': dureeTrajet,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'depart': depart,
        'arrive': arrive,
        'imgType': imgType.toString(),
      };

      tripDetailsList.add(tripDetails);

      setState(() {
        mainTripDetails = tripDetailsList;
        isRefreshed = false;
      });
      return tripDetailsList;
    } else {
      print(response.reasonPhrase);
    }
    return [];
  }

  String status = "";
  String acceptedStatus = "";

  Future<dynamic> acceptTrip(BuildContext context) {
    // print("Statues :${Status1}, ${Status2}, ${bkgColor}");
    return showModalBottomSheet(
      backgroundColor: Color(0xFFE6F7FD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 25,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Status',
                              style: TextStyle(
                                color: Color(0xFF524D4D),
                                fontSize: 18,
                                fontFamily: 'Kanit',
                                fontWeight: FontWeight.w400,
                                height: 0.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 75,
                      ),
                      Divider(
                        thickness: 0.5,
                        color: Colors.grey,
                      ),
                      Container(
                        color: Color(0xFFE6F7FD),
                        height: 50,
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 30,
                            ),
                            Flexible(
                              child: RadioListTile(
                                title: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Accepte',
                                      style: TextStyle(fontSize: 18),
                                    )),
                                value: "Accepte",
                                groupValue: status,
                                onChanged: (value) {
                                  setState(() {
                                    status = value.toString();
                                  });
                                },
                              ),
                            ),
                            Flexible(
                              child: RadioListTile(
                                title: Text(
                                  'Refuser',
                                  style: TextStyle(fontSize: 18),
                                ),
                                value: "Refuser",
                                groupValue: status,
                                onChanged: (value) {
                                  setState(() {
                                    status = value.toString();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 15,
                      ),
                      GestureDetector(
                        onTap: () {
                          print(
                              '==================================================');
                          setState(() {
                            isRefreshed = true;
                          });
                          updateTripStatus();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 333,
                          height: 49,
                          decoration: ShapeDecoration(
                            color: Color(0xFF3556A7),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            shadows: [
                              BoxShadow(
                                color: Color(0x07000000),
                                blurRadius: 10,
                                offset: Offset(0, 0),
                                spreadRadius: 8,
                              )
                            ],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                'Valider',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                  height: 0.04,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    )..whenComplete(() => setState(() {
          isRefreshed = true;
          Future.delayed(Duration(milliseconds: 500), () {
            setState(() {
              isRefreshed = false;
            });
          });
        }));
  }

  Future<dynamic> openAccepterBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      backgroundColor: Color(0xFFE6F7FD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setState,
          ) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 1.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 25,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Status',
                              style: TextStyle(
                                color: Color(0xFF524D4D),
                                fontSize: 18,
                                fontFamily: 'Kanit',
                                fontWeight: FontWeight.w400,
                                height: 0.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 75,
                      ),
                      Divider(
                        thickness: 0.5,
                        color: Colors.grey,
                      ),
                      // Add your additional RadioListTile widgets here
                      RadioListTile(
                        title: Text('En Route'),
                        value: "En route",
                        groupValue: acceptedStatus,
                        onChanged: (value) {
                          setState(() {
                            acceptedStatus = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text('Sur Place'),
                        value: "Sur place",
                        groupValue: acceptedStatus,
                        onChanged: (value) {
                          setState(() {
                            acceptedStatus = value.toString();
                            print(
                                'Second Status after accepted: $acceptedStatus');
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text('Client Abord'),
                        value: "Client abord",
                        groupValue: acceptedStatus,
                        onChanged: (value) {
                          setState(() {
                            acceptedStatus = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text('Absent + Displacement'),
                        value: "Client absent",
                        groupValue: acceptedStatus,
                        onChanged: (value) {
                          setState(() {
                            acceptedStatus = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: Text('Terminer'),
                        value: "Terminee",
                        groupValue: acceptedStatus,
                        onChanged: (value) {
                          setState(() {
                            acceptedStatus = value.toString();
                          });
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 15,
                      ),
                      GestureDetector(
                        onTap: () async {
                          // print('----------------$acceptedStatus-----------');
                          setState(() {
                            isRefreshed = true;
                          });
                          updateTripStatus2();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 333,
                          height: 49,
                          decoration: ShapeDecoration(
                            color: Color(0xFF3556A7),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            shadows: [
                              BoxShadow(
                                color: Color(0x07000000),
                                blurRadius: 10,
                                offset: Offset(0, 0),
                                spreadRadius: 8,
                              )
                            ],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                'Valider',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                  height: 0.04,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 15,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => setState(() {
          isRefreshed = true;
          Future.delayed(Duration(milliseconds: 500), () {
            setState(() {
              isRefreshed = false;
            });
          });
        }));
  }

  Color _getStatusColor(String status1, String status2) {
    switch ("$status1-$status2") {
      case '1-1':
        return Colors.grey;
      case '0-0':
        return Colors.orange;
      case '1-2':
        return Colors.yellow.shade600;
      case '1-5':
        return Colors.purple.shade900;
      case '1-3':
        return Colors.pink.shade400;
      case '1-4':
        return Colors.pink.shade900;
      case '1-0':
        return Colors.green;
      default:
        return Color(0xFF135DB9);
    }
  }

  String getStatusText(String status1, String status2) {
    String statusText;

    switch ("$status1-$status2") {
      case "0-0":
        statusText = "En Attente";
        break;
      case "1-0":
        statusText = "Accepter";
        break;
      case "1-1":
        statusText = "En Route";
        break;
      case "1-2":
        statusText = "Sur Place";
        break;
      case "1-3":
        statusText = "Absent + Deplacement";
        break;
      case "1-4":
        statusText = "Terminé";
        break;
      case "1-5":
        statusText = "Abord";
        break;
      default:
        statusText = "No Status Available";
        break;
    }

    return statusText;
  }

  Image? getImageBasedOnType(String imgType) {
    switch (imgType) {
      case "1":
        return Image.asset('assets/images/taxi.png');
      case "2":
        return Image.asset('assets/images/ambulance.png');
      case "3":
        return Image.asset('assets/images/school.png');
      default:
        return null;
    }
  }

  Future<void> updateTripStatus() async {
    final box = GetStorage();
    final _token = box.read('token') ?? '';

    final configData = await rootBundle.loadString('assets/config/config.json');
    final configJson = json.decode(configData);

    final gestionBaseUrl = configJson['planning_baseUrl'];
    final gestionApiKey = configJson['planning_apiKey'];

    final gestionMainUrl =
        gestionBaseUrl + "mob/course-accepte-refuse/" + id.toString();

    var headers = {
      'x-api-key': '$gestionApiKey',
      'Authorization': 'Bearer ' + _token
    };

    var request = http.Request('POST', Uri.parse(gestionMainUrl));
    request.body = json.encode({
      "etat": status,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());

      Get.snackbar(
        colorText: Colors.white,
        'Success',
        'Trip is Accepted',
        backgroundColor: Color.fromARGB(255, 8, 213, 59),
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        isDismissible: true,
        dismissDirection: DismissDirection.up,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInCirc,
        duration: const Duration(seconds: 3),
        barBlur: 0,
        messageText: const Text(
          'Trip is Accepted',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      );
      tripDetails();

      Get.to(() => TripDetails());

      setState(() {
        isRefreshed = false;
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> updateTripStatus2() async {
    final box = GetStorage();
    final _token = box.read('token') ?? '';

    final configData = await rootBundle.loadString('assets/config/config.json');
    final configJson = json.decode(configData);

    final gestionBaseUrl = configJson['planning_baseUrl'];
    final gestionApiKey = configJson['planning_apiKey'];

    final gestionMainUrl = gestionBaseUrl + "mob/course-etat/" + id.toString();

    var headers = {
      'x-api-key': '$gestionApiKey',
      'Authorization': 'Bearer ' + _token
    };

    var request = http.Request('POST', Uri.parse(gestionMainUrl));
    request.body = json.encode({
      "etat2": acceptedStatus,
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());

      Get.snackbar(
        colorText: Colors.white,
        'Success',
        'Trip is Updated',
        backgroundColor: Color.fromARGB(255, 8, 213, 59),
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        isDismissible: true,
        dismissDirection: DismissDirection.up,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInCirc,
        duration: const Duration(seconds: 3),
        barBlur: 0,
        messageText: const Text(
          'Trip is Updated',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      );
      tripDetails();

      Get.to(() => TripDetails());

      setState(() {
        isRefreshed = false;
      });

      // Navigator.of(context).pop();
    } else {
      print(response.reasonPhrase);
    }
  }

  void _addMarkers() {
    // Add markers for the two points on the map
    _markers.add(
      Marker(
        markerId: MarkerId('point1'),
        position: LatLng(37.7749, -122.4194), // Point 1 coordinates
        infoWindow: InfoWindow(title: 'Point 1'),
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId('point2'),
        position: LatLng(37.7749, -122.4294), // Point 2 coordinates
        infoWindow: InfoWindow(title: 'Point 2'),
      ),
    );
  }

  void _calculateDistance() async {
    // Calculate the distance between two points
    double distanceInMeters = await Geolocator.distanceBetween(
      37.7749, -122.4194, // Point 1 coordinates
      37.7749, -122.4294, // Point 2 coordinates
    );

    print('Distance: ${distanceInMeters / 1000} km');
  }

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    List<dynamic> userRoles = storage.read('user_roles') ?? [];
    bool isChauffeur = userRoles.contains('ROLE_CHAUFFEUR');
    bool isAdmin = userRoles.contains('ROLE_ADMIN');

    // String statusText = getStatusText(Status1, Status2);
    return Scaffold(
      body: isRefreshed
          ? Center(
              child: CircularProgressIndicator(
              color: Color(0xFF3954A4),
            ))
          : SingleChildScrollView(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            (isChauffeur)
                                ? Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => HomeScreen()))
                                : (isAdmin)
                                    ? Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => Cart()))
                                    : null;
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            size: 30,
                            color: Color(0xFF3954A4),
                          ))
                    ],
                  ),
                ),
                // SizedBox(
                //   height: MediaQuery.of(context).size.height / 35,
                // ),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    width: MediaQuery.of(context).size.width / 1.12,
                    height: 170,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 0),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: isRefreshed
                        ? Center(
                            child: CircularProgressIndicator(
                            color: Color(0xFF3954A4),
                          ))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: mainTripDetails.length,
                            itemBuilder: (context, index) {
                              final item = mainTripDetails[index];
                              String Status1 = item['status1'];
                              String Status2 = item['status2'];
                              String imgType = item['imgType'].toString();
                              String date = item['dateCourse'];
                              String borderColor = item['backgroundColor'];
                              print(
                                  'Background color from the list: $borderColor');
                              DateTime dateTime = DateTime.parse(date);
                              tz.TZDateTime parisDateTime = tz.TZDateTime.from(
                                  dateTime, tz.getLocation('Europe/Paris'));

                              String formattedDate =
                                  DateFormat('dd.MMM.yyyy \nhh:MM')
                                      .format(parisDateTime);

                              return Column(
                                // mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item['nom']} ${item['prenom']}',
                                          // '$nom $prenom',
                                          style: TextStyle(
                                            color: Color(0xFF524D4D),
                                            fontSize: 18,
                                            fontFamily: 'Kanit',
                                            fontWeight: FontWeight.w500,
                                            height: 0,
                                          ),
                                        ),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Color(0xFF524D4D),
                                            fontSize: 17,
                                            fontFamily: 'Kanit',
                                            fontWeight: FontWeight.w500,
                                            height: 0,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.zero,
                                          width: 40,
                                          height: 40,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: OvalBorder(),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0x3F000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0),
                                                spreadRadius: 0,
                                              )
                                            ],
                                          ),
                                          child: getImageBasedOnType(imgType),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // SizedBox(
                                  //   height: 10,
                                  // ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            if (isChauffeur) {
                                              if (Status1 == "0" &&
                                                  Status2 == "0") {
                                                acceptTrip(context);
                                              } else if ((Status1 == "1" &&
                                                      Status2 == "3") ||
                                                  Status1 == "1" &&
                                                      Status2 == "4") {
                                                null;
                                              } else {
                                                openAccepterBottomSheet(
                                                    context);
                                              }
                                            } else {
                                              null;
                                            }
                                          },
                                          child: Container(
                                            // width: 220,
                                            height: 24,
                                            decoration: ShapeDecoration(
                                              color: _getStatusColor(
                                                  Status1, Status2),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                child: Text(
                                                  getStatusText(
                                                      Status1, Status2),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontFamily: 'Kanit',
                                                    fontWeight: FontWeight.w500,
                                                    height: 0,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                )),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () async {
                                                print(
                                                    'telephone Number: $telephoneNumber');
                                                final call = Uri.parse(
                                                    'tel: $telephoneNumber');
                                                if (await canLaunchUrl(call)) {
                                                  launchUrl(call);
                                                } else {
                                                  throw 'Could not launch $call';
                                                }
                                              },
                                              child: Container(
                                                width: 42,
                                                height: 34,
                                                decoration: ShapeDecoration(
                                                  color: Color(0xFFECF4FF),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5)),
                                                ),
                                                child: Icon(
                                                  Icons.phone,
                                                  size: 20,
                                                  color: Color(0xFF135DB9),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () {
                                                Get.to(() => MapsScreen());
                                              },
                                              child: Container(
                                                  width: 42,
                                                  height: 34,
                                                  decoration: ShapeDecoration(
                                                    color: Color(0xFFECF4FF),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5)),
                                                  ),
                                                  child: Image.asset(
                                                      'assets/images/maps.png')),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: Container(
                                              width: 104,
                                              height: 34,
                                              decoration: ShapeDecoration(
                                                color: Color(0xFFECF4FF),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Row(
                                                  children: [
                                                    Image.asset(
                                                        'assets/images/watch.png'),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      "$time"
                                                      " minutes",
                                                      // '9 minutes',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF6E6868),
                                                        fontSize: 12,
                                                        fontFamily: 'Kanit',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 0,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                ],
                              );
                            })),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.12,
                  height: MediaQuery.of(context).size.height / 5.5,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            Image.asset('assets/images/location2.png'),
                            SizedBox(
                              width: 20,
                            ),
                            Image.asset('assets/images/car.png'),
                            SizedBox(
                              width: 20,
                            ),
                            Flexible(
                              child: Text(
                                address1 ?? 'Address to be filled',
                                style: TextStyle(
                                  color: Color(0xFF524D4D),
                                  fontSize: 14,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w400,
                                  height: 0,
                                ),
                                overflow: TextOverflow.clip,
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            Image.asset('assets/images/car4.png'),
                            SizedBox(
                              width: 20,
                            ),
                            Image.asset('assets/images/location5.png'),
                            SizedBox(
                              width: 20,
                            ),
                            Flexible(
                              child: Text(
                                address2 ?? 'Address to be filled',
                                style: TextStyle(
                                  color: Color(0xFF524D4D),
                                  fontSize: 14,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w400,
                                  height: 0,
                                ),
                                overflow: TextOverflow.clip,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.12,
                  height: 450,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ListTile(
                        leading: Text(
                          'Trajet',
                          style: TextStyle(
                            color: Color(0xFF524D4D),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        trailing: Text(
                          distance,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF3954A4),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Text(
                          'Type de paiement',
                          style: TextStyle(
                            color: Color(0xFF524D4D),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        trailing: Text(
                          payment,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF3954A4),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Text(
                          'Commentaire',
                          style: TextStyle(
                            color: Color(0xFF524D4D),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        trailing: Text(
                          comment,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF3954A4),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      ),
                      ListTile(
                          leading: Text(
                            'Fichier 1:',
                            style: TextStyle(
                              color: Color(0xFF524D4D),
                              fontSize: 14,
                              fontFamily: 'Kanit',
                              fontWeight: FontWeight.w400,
                              height: 0,
                            ),
                          ),
                          trailing: (file1 != "")
                              ? TextButton(
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        'https://docs.google.com/gview?embedded=true&url=${file1}'));
                                  },
                                  child: Text(pdfFileName),
                                )
                              : Icon(
                                  Icons.visibility,
                                  color: Color(0xFF3954A4),
                                )),
                      ListTile(
                          leading: Text(
                            'Fichier 2:',
                            style: TextStyle(
                              color: Color(0xFF524D4D),
                              fontSize: 14,
                              fontFamily: 'Kanit',
                              fontWeight: FontWeight.w400,
                              height: 0,
                            ),
                          ),
                          trailing: (file2 != "")
                              ? TextButton(
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        'https://docs.google.com/gview?embedded=true&url=${file2}'));
                                  },
                                  child: Text(pdfFileName),
                                )
                              : Icon(
                                  Icons.visibility,
                                  color: Color(0xFF3954A4),
                                )),
                      ListTile(
                        leading: Text(
                          'Chauffeur',
                          style: TextStyle(
                            color: Color(0xFF524D4D),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        trailing: Text(
                          '${nom} ${prenom}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF3954A4),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Text(
                          'Référence',
                          style: TextStyle(
                            color: Color(0xFF524D4D),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                            height: 0,
                          ),
                        ),
                        trailing: Text(
                          referenceNumber,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF3954A4),
                            fontSize: 14,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 90,
                )
              ]),
            ),
    );
  }
}
