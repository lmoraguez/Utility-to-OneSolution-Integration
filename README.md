# Utility-to-OneSolution-Integration
A set of views that seamlessly integrate the OneSolution CAD database with Utility's AVaiL system without exposing any sensitive information in CAD.

Code is Open Sourced under the GNU Lesser Public License v3.0.  Contributors are welcome, but please link to this main branch and include credit to the original source of your contribution.

# Current Features allow Utility to:
- Auto-associate CAD event number and Case number to officer video
- Auto-relate video recordings of various officers based on the event numbers associated
- Auto-classify videos based on a CAD nature code to video classification mapping. (Maintained through CAD GUI & SQL)

# Future Features in the works:
- Auto-recording based on CAD defined Action Zones (Action Zones are an option that can be set up with Utility Inc, and this integration aims to allow for those action zones to be defined and maintained through the CAD GUI).
- Auto-usermaintenance view, so that when an officer is hired, promoted, or seperated from the agency, they will be automatically added/maintained in AVaiL, and disabled if that officer were to seperate from the agency.

# Installation Notes:
 Installation services available if needed. Basic service includes:
- Tayloring the views to your environment, locality (state plane formulas), & features needed
- Training on the features available and tweaks that can be made

Additional/Optional services
- Integrating with the CAD Training Environment
- Updating integration as new features are added 

*Let Utility know that you would like their expert with OneSolution CAD to perform the installation for you, and they will get them in contact with you to schedule the install.

If you prefer the DIY route, below is the general outline of how to do so.
- 1. The views in this repository should be installed first.
- 2. The stored procedures and table installation scripts (provided by Utility) should be customized to match your environment and references to the views installed step 1.
- 3. Create a user in SQL that only has access to the views, stored procedures, and tables created.
- 4. Utility CAD Integration Service needs to be configured and installed on a server that will allow it to connect to the Stored Procedures installed in step 2. This service will transfer data to AVaiL over a secure connection.
