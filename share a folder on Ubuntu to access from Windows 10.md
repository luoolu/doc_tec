## Share Ubuntu folder on SAMBA

1. Open Ubuntu’s File Manager.
2. Right-click on the folder that you want to share.
3. Here we are sharing the Pictures folder of our Ubuntu 20.04 LTS PC.
![image](https://user-images.githubusercontent.com/18479844/178174999-4e557075-9fba-4f4c-8297-94521a879d7b.png)
4. Select the Properties option.
5. Click on the Local Network Share TAB.
6. Select the box given in front of the option “Share this folder“.
7. A pop-up will appear to install the SAMBA package on the system. Install it by providing your current account user password.
8. By default, the Share name will be the name of the folder. However, you can change it whatever you want.
9. Next, mark the “Allow others to create and delete files in this folder” option. If you want to write the files to the shared location remotely.
10. Another option is “Guest access (for people without a user account“. By default, the users with an account can access the shared folders. In case, you want to allow anonymous users to access them, check this one otherwise leave it. However, if you are locally accessing the folder then check it for easy access.
![image](https://user-images.githubusercontent.com/18479844/178175146-a44df5f8-195a-4a75-9193-d9cbd75008ff.png)
11. Finally, click on the Modify Share button and allow the setup to set permissions for the Ubuntu shared folder or files.
![image](https://user-images.githubusercontent.com/18479844/178175202-dc44871e-b0ab-46ea-89db-05bda9e388cd.png)
12. Open Command Terminal.
13. Type: ifconfig
14. And note down the IP address of your machine.

## Access the Ubuntu shared folder on Windows 10 remotely

1. On the Windows 10 or 7, open MyComputer.
2. Right-click anywhere on the blank space and select “Add a Network Location“.
![image](https://user-images.githubusercontent.com/18479844/178175442-8c09f40e-9ce0-47ee-9427-98c34964bbd5.png)
3. Network location wizard will open, click on the “NEXT” button.
4. Select “Choose a custom Network location” option.
5. Add the address of the folder shared on the Ubuntu. For that type \\ip-address-ubuntu\shared-folder name
6. For example, in our case, the system IP address was- 192.168.0.107 and the shared folder named “Pictures”. Thus, the address will be \\192.168.0.107\Pictures
![image](https://user-images.githubusercontent.com/18479844/178175521-434d41ec-6e8b-4238-bba5-cf49d5e1736d.png)
7. In the same way, you also have to add the address and click on the Next button.
8. Windows will automatically find the share Ubuntu folder and add it.
![image](https://user-images.githubusercontent.com/18479844/178175577-f7a12d6b-d243-4c05-9f60-8dc081a0a31e.png)
9. Now, go to the Windows 10 or 7 MyPC area and start accessing the shared Ubuntu folder and files via SAMBA protocol.
![image](https://user-images.githubusercontent.com/18479844/178175626-c25dbb5d-8b8d-4d8b-9c43-fa7bb39e9887.png)















