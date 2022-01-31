SuperStrict

Framework brl.standardio
Import text.json
Import brl.linkedlist
Import brl.map

Local apiFile:String = "../sdk/public/steam/steam_api.json"

Local stream:TStream = ReadStream(apiFile)

If Not stream Then
	Throw apiFile + " not found."
End If

Local error:TJSONError

Local json:TJSONObject = TJSONObject(TJSON.Load(stream, 0, error))

Local enums:TList = ParseEnums(TJSONArray(json.Get("enums")))
Local typeMapping:TTypeMapping = ParseTypeMappings(TJSONArray(json.Get("typedefs")))
'Local classes:TClasses = ParseMethods(TJSONArray(json.Get("methods")))

For Local sEnum:TEnum = EachIn enums
	sEnum.Write(Null)
Next

Type TTypeMapping

	Field map:TStringMap = New TStringMap
	
	Method New()
		Init()
	End Method

	Method Init()
		map.Insert("unsigned char", "Byte")
		map.Insert("signed char", "Byte")
		map.Insert("short", "Short")
		map.Insert("unsigned short", "Short")
		map.Insert("int", "Int")
		map.Insert("unsigned int", "UInt")
		map.Insert("long long", "Long")
		map.Insert("unsigned long long", "ULong")
		map.Insert("uint8 [8]", "Byte Ptr")
		map.Insert("const void *", "Byte Ptr")
		map.Insert("void *", "Byte Ptr")
		map.Insert("bool", "Int")
		map.Insert("uint32 *", "UInt Ptr")
		map.Insert("class CSteamID", "ULong")
		map.Insert("const char *", "String")
		map.Insert("char *", "String")
	End Method

	Method AddType(orig:String, typeToMap:String)
		Local mapped:String = String(map.ValueForKey(typeToMap))
		If Not mapped Then
			map.Insert(orig, typeToMap)
			Print "No mapping for " + orig + " -> " + typeToMap
		Else
			Local actualMapped:String = String(map.ValueForKey(mapped))
			If Not actualMapped Then
				map.Insert(orig, mapped)
				Print "Mapping " + orig + " to " + mapped
			Else
				map.Insert(orig, actualMapped)
				Print "Mapping " + orig + " to " + actualMapped
			End If
		End If
	End Method
End Type


Type TEnum

	Global flagEnums:String[] = ["EAppOwnershipFlags", "EAppType", "EPersonaChange", "EMarketNotAllowedReasonFlags", ..
		"EFriendFlags", "EUserRestriction", "EChatMemberStateChange", "ERemoteStoragePlatform", "ESteamItemFlags", ..
		"EHTMLKeyModifiers"]

	Field name:String
	Field isFlags:Int
	Field values:TList = New TList
	
	Method New(name:String)
		If name.Find("::") >= 0 Then
			name = name[name.Find("::") + 2..]
		End If
		isFlags = IsFlagEnum(name)
		Self.name = name
	End Method
	
	Method Write(stream:TStream)
		Local f:String
		If isFlags Then
			f = " Flags"
		End If
		Print "Enum " + name + f
		For Local value:TEnumValue = EachIn values
			value.Write(stream)
		Next
		Print "End Enum~n"
	End Method
	
	Function IsFlagEnum:Int(name:String)
		For Local f:String = EachIn flagEnums
			If f = name Then
				Return True
			End If
		Next
		Return False
	End Function
End Type

Type TEnumValue
	Field name:String
	Field value:String
	
	Method New(name:String, value:String)
		Self.name = name
		Self.value = value
	End Method
	
	Method Write(stream:TStream)
		Print "~t" + name + " = " + value
	End Method
End Type

Type TClasses

	Field classes:TStringMap = New TStringMap

	Method GetClass:TClassDef(name:String)
		Local class:TClassDef = TClassDef(classes.ValueForKey(name))
		If Not class Then
			Print "Creating type : " + name
			class = New TClassDef(name)
			classes.Insert(name, class)
		End If
		Return class
	End Method

End Type

Type TClassDef

	Field name:String
	Field methods:TList = New TList
	
	Method New(name:String)
		Self.name = name
	End Method
	
	Method AddMethod(meth:TClassMethod)
		methods.AddLast(meth)
	End Method
	
End Type

Type TClassMethod
	Field name:String
	Field returnType:String
	Field args:TList = New TList
	
	Method New(name:String)
		Self.name = name
	End Method
	
	Method AddArg(arg:TMethodArg)
		args.AddLast(arg)
	End Method
	
End Type

Type TMethodArg
	Field name:String
	Field argType:String
	
	Method New(name:String, argType:String)
		Self.name = name
		Self.argType = argType
	End Method
End Type

Function ParseEnums:TList(enums:TJSONArray)
	Local list:TList = New TList
	
	For Local obj:TJSONObject = EachIn enums
		
		Local sEnum:TEnum = New TEnum(obj.GetString("enumname"))
		list.AddLast(sEnum)
		
		Local values:TJSONArray = TJSONArray(obj.Get("values"))
		
		For Local val:TJSONObject = EachIn values
			Local value:TEnumValue = New TEnumValue(val.GetString("name"), val.GetString("value"))
			sEnum.values.AddLast(value)
		Next
	Next
	
	Return list
End Function

Function ParseTypeMappings:TTypeMapping(typedefs:TJSONArray)
	Local typeMapping:TTypeMapping = New TTypeMapping
	
	For Local obj:TJSONObject = EachIn typedefs
		typeMapping.AddType(obj.GetString("typedef"), obj.GetString("type"))
	Next
	
	Return typeMapping
End Function

Function ParseMethods:TClasses(methods:TJSONArray)
	Local classes:TClasses = New TClasses
	
	For Local obj:TJSONObject = EachIn methods
	
		Local class:TClassDef = classes.GetClass(obj.GetString("classname"))
		
		Local meth:TClassMethod = New TClassMethod(obj.GetString("methodname"))
		class.AddMethod(meth)
		
		Local returnType:String = obj.GetString("returntype")
		
		If returnType <> "void" Then
			meth.returnType = returnType
		End If
	
		Local params:TJSONArray = TJSONArray(obj.Get("params"))

		If params Then
			For Local param:TJSONObject = EachIn params
				Local arg:TMethodArg = New TMethodArg(param.GetString("paramname"), param.GetString("paramtype"))
				meth.AddArg(arg)
			Next
		End If
	
	Next
	
	
	Return classes
End Function

' EGamepadTextInputLineMode|Controls number of allowed lines for the Big Picture gamepad text entry
' EGamepadTextInputMode|Input modes for the Big Picture gamepad text entry
' ECheckFileSignature|The result of a call to #CheckFileSignature
' ESteamAPICallFailure|Steam API call failure results returned by #GetAPICallFailureReason
