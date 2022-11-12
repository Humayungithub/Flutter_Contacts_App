import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:contact_app/app-contact.class.dart';
import 'package:contact_app/components/contacts-list.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.user,}) : super(key: key);

  final User user;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppContact> contacts = [];
  List<AppContact> contactsFiltered = [];
  Map<String, Color> contactsColorMap = new Map();
  TextEditingController searchController = new TextEditingController();
  bool contactsLoaded = false;

  @override
  void initState() {
    super.initState();
    getPermissions();
  }

  getPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      getAllContacts();
      searchController.addListener(() {
        filterContacts();
      });
    }
  }

  String flattenPhoneNumber(String phoneStr) {
    return phoneStr.replaceAllMapped(RegExp(r'^(\+)|\D'), (Match m) {
      return m[0] == "+" ? "+" : "";
    });
  }


  getAllContacts() async {
    List colors = [
      Colors.green,
      Colors.indigo,
      Colors.yellow,
      Colors.orange
    ];
    int colorIndex = 0;
    List<AppContact> _contacts = (await ContactsService.getContacts()).map((contact) {
      Color baseColor = colors[colorIndex];
      colorIndex++;
      if (colorIndex == colors.length) {
        colorIndex = 0;
      }
      return new AppContact(info: contact, color: baseColor);
    }).toList();
    setState(() {
      contacts = _contacts;
      contactsLoaded = true;
    });
  }

  filterContacts() {
    List<AppContact> _contacts = [];
    _contacts.addAll(contacts);
    if (searchController.text.isNotEmpty) {
      _contacts.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String searchTermFlatten = flattenPhoneNumber(searchTerm);
        String contactName = contact.info.displayName!.toLowerCase();
        bool nameMatches = contactName.contains(searchTerm);
        if (nameMatches == true) {
          return true;
        }

        if (searchTermFlatten.isEmpty) {
          return false;
        }

        var phone = contact.info.phones!.firstWhere((phn) {
          String phnFlattened = flattenPhoneNumber(phn.value.toString());
          return phnFlattened.contains(searchTermFlatten);
        }, orElse: null);

        return phone != null;
      });
    }
    setState(() {
      contactsFiltered = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    bool listItemsExist = (
        (isSearching == true && contactsFiltered.length > 0) ||
            (isSearching != true && contacts.length > 0)
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColorDark,
        child: const Icon(Icons.add),
        onPressed: () async {
          try {
            print('Hi I am asdfafadfad');
            Contact contact = await ContactsService.openContactForm();
            if (contact != null) {
              getAllContacts();
            }
          } on FormOperationException catch (e) {
            switch(e.errorCode) {
              case FormOperationErrorCode.FORM_OPERATION_CANCELED:
              case FormOperationErrorCode.FORM_COULD_NOT_BE_OPEN:
              case FormOperationErrorCode.FORM_OPERATION_UNKNOWN_ERROR:
              default: // Do nothing
                print(e.toString());
            }
          }
        },
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Container(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                    labelText: 'search through all contacts',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(45.0),
                        borderSide: BorderSide(
                          width: 2.0,
                          color: Theme.of(context).primaryColor,
                        )),
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).primaryColor)),
              ),
            ),
            contactsLoaded == true ?  // if the contacts have not been loaded yet
            listItemsExist == true ?  // if we have contacts to show
            ContactsList(
              reloadContacts: () {
                getAllContacts();
              },
              contacts: isSearching == true ? contactsFiltered : contacts,
            ) : Container(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  isSearching ?'No search results to show' : 'No contacts exist',
                  style: TextStyle(color: Colors.grey, fontSize: 20),
                )
            ) :
            Container(  // still loading contacts
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
            // Expanded(
            //     child: ListView.builder(
            //   shrinkWrap: true,
            //   itemCount: isSearching == true ? contactsFiltered.length : contacts.length,
            //   itemBuilder: (context, index) {
            //     Contact contact = isSearching == true ? contactsFiltered[index] : contacts[index];
            //     return ListTile(
            //         title: Text(contact.displayName.toString()),
            //         subtitle:
            //             Text(contact.phones!.elementAt(0).value.toString()),
            //         leading:
            //             (contact.avatar != null && (contact.avatar?.length)! > 0)
            //                 ? CircleAvatar(
            //                     backgroundImage: MemoryImage(contact.avatar!),
            //                   )
            //                 : CircleAvatar(child: Text(contact.initials())));
            //   },
            // ))
          ],
        ),
      ),
    );
  }
}

