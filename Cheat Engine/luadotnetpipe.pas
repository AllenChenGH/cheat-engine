unit LuaDotNetPipe;

{$mode delphi}

interface

uses
  Classes, SysUtils;

procedure initializeLuaDotNetPipe;

implementation

uses luahandler, lua, lauxlib, lualib, luaclass, LuaObject, symbolhandler, dotnetpipe, Maps;

function dotnetpipe_enumDomains(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  domains: TDotNetDomainArray;
  i: integer;
  arraytable: integer;
begin
  dnp:=luaclass_getClassObject(L);

  setlength(domains,0);
  dnp.EnumDomains(domains);
  lua_createtable(L,length(domains),0);

  for i:=0 to length(domains)-1 do
  begin
    lua_pushinteger(L,i+1);
    lua_createtable(L,0,2);

    lua_pushstring(L, 'DomainHandle');
    lua_pushinteger(L, domains[i].hDomain);
    lua_settable(L,-3); //entry

    lua_pushstring(L, 'Name');
    lua_pushstring(L, domains[i].Name);
    lua_settable(L,-3); //entry

    lua_settable(L,-3); //array
  end;

  result:=1;

end;

function dotnetpipe_enumModuleList(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  domain: uint64;
  modules: TDotNetModuleArray;
  i: integer;
begin
  result:=0;
  dnp:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
  begin
    domain:=lua_tointeger(L,1);

    setlength(modules,0);
    dnp.EnumModuleList(domain, modules);

    lua_createtable(L,length(modules),0);

    for i:=0 to length(modules)-1 do
    begin
      lua_pushinteger(L,i+1);
      lua_createtable(L,0,3);

      lua_pushstring(L, 'ModuleHandle');
      lua_pushinteger(L, modules[i].hModule);
      lua_settable(L,-3);

      lua_pushstring(L, 'BaseAddress');
      lua_pushinteger(L, modules[i].baseaddress);
      lua_settable(L,-3);

      lua_pushstring(L, 'Name');
      lua_pushstring(L, modules[i].Name);
      lua_settable(L,-3);

      lua_settable(L,-3);
    end;

    result:=1;
  end;
end;

function dotnetpipe_enumTypeDefs(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  modulehandle: uint64;
  typedefs: TDotNetTypeDefArray;
  i: integer;
begin
  result:=0;
  dnp:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
  begin
    modulehandle:=lua_tointeger(L,1);

    setlength(typedefs,0);
    dnp.EnumTypeDefs(modulehandle, typedefs);

    lua_createtable(L,length(typedefs),0);

    for i:=0 to length(typedefs)-1 do
    begin
      lua_pushinteger(L,i+1);
      lua_createtable(L,0,4);

      lua_pushstring(L, 'TypeDefToken');
      lua_pushinteger(L, typedefs[i].token);
      lua_settable(L,-3);

      lua_pushstring(L, 'Name');
      lua_pushstring(L, typedefs[i].Name);
      lua_settable(L,-3);

      lua_pushstring(L, 'Flags');
      lua_pushinteger(L, typedefs[i].flags);
      lua_settable(L,-3);

      lua_pushstring(L, 'Extends');
      lua_pushinteger(L, typedefs[i].extends);
      lua_settable(L,-3);

      lua_settable(L,-3);
    end;

    result:=1;
  end;
end;

function dotnetpipe_getTypeDefMethods(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  modulehandle: uint64;
  typedeftoken: uint64;
  methods: TDotNetMethodArray;
  i,j: integer;
begin
  result:=0;
  dnp:=luaclass_getClassObject(L);
  if lua_gettop(L)>=2 then
  begin
    modulehandle:=lua_tointeger(L,1);
    typedeftoken:=lua_tointeger(L,2);

    setlength(methods,0);
    dnp.GetTypeDefMethods(modulehandle, typedeftoken, methods);

    lua_createtable(L,length(methods),0);

    for i:=0 to length(methods)-1 do
    begin
      //MethodToken, Name, Attributes, ImplementationFlags, ILCode, NativeCode, SecondaryNativeCode[]

      lua_pushinteger(L,i+1);
      lua_createtable(L,0,4);

      lua_pushstring(L, 'MethodToken');
      lua_pushinteger(L, methods[i].token);
      lua_settable(L,-3);

      lua_pushstring(L, 'Name');
      lua_pushstring(L, methods[i].Name);
      lua_settable(L,-3);

      lua_pushstring(L, 'Attributes');
      lua_pushinteger(L, methods[i].Attributes);
      lua_settable(L,-3);

      lua_pushstring(L, 'ImplementationFlags');
      lua_pushinteger(L, methods[i].implflags);
      lua_settable(L,-3);

      lua_pushstring(L, 'ILCode');
      lua_pushinteger(L, methods[i].ILCode);
      lua_settable(L,-3);

      lua_pushstring(L, 'NativeCode');
      lua_pushinteger(L, methods[i].NativeCode);
      lua_settable(L,-3);

      lua_pushstring(L, 'SecondaryNativeCode');
      lua_createtable(L, length(methods[i].SecondaryNativeCode),0);

      for j:=0 to length(methods[i].SecondaryNativeCode)-1 do
      begin
        lua_pushinteger(L,i+1);
        lua_pushinteger(L,methods[i].SecondaryNativeCode[j].address);
        lua_settable(L,-3);
      end;

      lua_settable(L,-3);
    end;

    result:=1;
  end;
end;

function dotnetpipe_getAddressData(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  address: uint64;
  addressData: TAddressData;
  i: integer;
begin
  result:=0;
  dnp:=luaclass_getClassObject(L);
  if lua_gettop(L)>=1 then
  begin
    address:=lua_tointeger(L,1);

    FillByte(addressData, sizeof(addressData),0);
    dnp.GetAddressData(address, addressData);

    if addressdata.startaddress=0 then exit(0);

    lua_createtable(L,0,8);
    lua_pushstring(L,'StartAddress');
    lua_pushinteger(L, addressData.startaddress);
    lua_settable(L,-3);

    lua_pushstring(L,'ObjectType');
    lua_pushinteger(L, addressData.ObjectType);
    lua_settable(L,-3);

    lua_pushstring(L,'ElementType');
    lua_pushinteger(L, addressData.ElementType);
    lua_settable(L,-3);

    lua_pushstring(L,'CountOffset');
    lua_pushinteger(L, addressData.CountOffset);
    lua_settable(L,-3);

    lua_pushstring(L,'ElementSize');
    lua_pushinteger(L, addressData.ElementSize);
    lua_settable(L,-3);

    lua_pushstring(L,'FirstElementOffset');
    lua_pushinteger(L, addressData.FirstElementOffset);
    lua_settable(L,-3);

    lua_pushstring(L,'ClassName');
    lua_pushstring(L, addressData.ClassName);
    lua_settable(L,-3);

    lua_pushstring(L,'Fields');
    lua_createtable(L, length(addressData.fields),0);
    for i:=0 to length(addressData.Fields)-1 do
    begin
      lua_pushinteger(L, i+1);
      lua_createtable(L,0,3);

      lua_pushstring(L,'Offset');
      lua_pushinteger(L, addressData.fields[i].offset);
      lua_settable(L,-3);

      lua_pushstring(L,'FieldType');
      lua_pushinteger(L, addressData.fields[i].fieldtype);
      lua_settable(L,-3);

      lua_pushstring(L,'Name');
      lua_pushstring(L, addressData.fields[i].name);
      lua_settable(L,-3);


      lua_settable(L,-3);
    end;
    lua_settable(L,-3);



    result:=1;
  end;
end;

function dotnetpipe_enumAllObjects(L: PLua_state): integer; cdecl;
var
  dnp: TDotNetPipe;
  address: uint64;
  addressData: TAddressData;
  i: integer;

  map: TDOTNETObjectList;
  mi: TMapIterator=nil;

  dno: PDotNetObject;
begin
  result:=0;
  dnp:=luaclass_getClassObject(L);

  map:=dnp.EnumAllObjects;
  mi:=TMapIterator.Create(map);
  try
    lua_createtable(L,map.Count,0);

    i:=1;
    mi.First;
    while not mi.EOM do
    begin
      dno:=mi.DataPtr;

      lua_pushinteger(L,i);
      lua_createtable(L,4,0);
      //entry table

      lua_pushstring(L,'StartAddress');
      lua_pushinteger(L,dno^.startaddress);
      lua_settable(L,-3);

      lua_pushstring(L,'Size');
      lua_pushinteger(L,dno^.size);
      lua_settable(L,-3);

      lua_pushstring(L,'TypeID');
      lua_createtable(L,0,2);
      //-1=typeid table

      lua_pushstring(L,'token1');
      lua_pushinteger(L,dno^.typeid.token1);
      lua_settable(L,-3);

      lua_pushstring(L,'token2');
      lua_pushinteger(L,dno^.typeid.token2);
      lua_settable(L,-3);

      lua_settable(L,-3); //typeid table

      //-1=entry table

      lua_pushstring(L,'Size');
      lua_pushinteger(L,dno^.size);
      lua_settable(L,-3);

      lua_settable(L,-3); //set entry to index

      mi.Next;
    end;

    result:=1;  //return the table
  finally
    mi.free;
    dnp.freeNETObjectList(map);
  end;


end;

function lua_getDotNetDataCollector(L: PLua_state): integer; cdecl;
begin
  luaclass_newClass(L, symhandler.getDotNetDataCollector);
  result:=1;
end;

procedure dotnetpipe_addMetaData(L: PLua_state; metatable: integer; userdata: integer );
begin
  object_addMetaData(L, metatable, userdata);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'enumDomains', dotnetpipe_enumDomains);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'enumModuleList', dotnetpipe_enumModuleList);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'enumTypeDefs', dotnetpipe_enumTypeDefs);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getTypeDefMethods', dotnetpipe_getTypeDefMethods);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getAddressData', dotnetpipe_getAddressData);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'enumAllObjects', dotnetpipe_enumAllObjects);
end;

procedure initializeLuaDotNetPipe;
begin
  lua_register(LuaVM, 'getDotNetDataCollector', lua_getDotNetDataCollector);
end;

initialization
  luaclass_register(TDotNetPipe, dotnetpipe_addMetaData);

end.

