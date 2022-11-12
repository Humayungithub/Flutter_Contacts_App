import 'package:contact_app/app-contact.class.dart';
import 'package:contact_app/screens/contact-details.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contact-avatar.dart';

class ContactsList extends StatelessWidget {
  final List<AppContact> contacts;
  Function() reloadContacts;
  ContactsList({Key? key, required this.contacts, required this.reloadContacts}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          AppContact contact = contacts[index];

          return ListTile(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => ContactDetails(
                      contact,
                      onContactDelete: (AppContact _contact) {
                        reloadContacts();
                        Navigator.of(context).pop();
                      },
                      onContactUpdate: (AppContact _contact) {
                        reloadContacts();
                      },
                    )
                ));
              },
              title: Text(contact.info.displayName.toString()),
              subtitle: Text(
                  ((contact.info.phones).toString().length)! > 0 ? contact.info.phones!.elementAt(0).value.toString() : ''
              ),
              leading: ContactAvatar(contact, 36),
             trailing: IconButton(
               icon: Icon(Icons.call),
               onPressed: () {
                 launch('tel: ${contact.info.phones!.elementAt(0).value}');
               },
             )
          );
        },

      ),
    );
  }
}