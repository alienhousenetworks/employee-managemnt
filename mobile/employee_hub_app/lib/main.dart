import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
void main()=>runApp(const EmployeeHubApp());
class EmployeeHubApp extends StatelessWidget{const EmployeeHubApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(title:'Employee Hub',debugShowCheckedModeBanner:false,theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFFB7F34A)),useMaterial3:true),home:const LoginScreen());}
