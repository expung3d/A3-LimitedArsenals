if(!isNull (findDisplay 312) && {!isNil "this"} && {!isNull this}) then {
	deleteVehicle this;
};

private _varName = "MAZ_System_EnhancementPack_LimitedArsenals";
private _myJIPCode = "MAZ_EPSystem_LA_JIP";

private _value = (str {
    MAZ_fnc_limitArsenals = {
        MAZ_fnc_getItemDisplayName = {
            params ["_className"];
            private _displayName = '';
            _displayName = getText (configFile >> "cfgVehicles" >> _x >> "displayName");
            if (_displayName == '') then {
                _displayName = getText (configFile >> "cfgMagazines" >> _x >> "displayName");
            };
            if (_displayName == '') then {
                _displayName = getText (configFile >> "cfgWeapons" >> _x >> "displayName");
            };
            if (_displayName == '') then {
                _displayName = getText (configFile >> "CfgGlasses" >> _x >> "displayName");
            };
            if (_displayName == '') then {
                _displayName = _className;
            };
            _displayName;
        };

        MAZ_fnc_deleteObjectServer = {
            params ["_objects"];
            [[_objects], {
                params ["_objects"];
                {
                    deleteVehicle _x;
                }forEach _objects;
            }] remoteExec ["spawn",2];
        };

        MAZ_fnc_removeBodiesNearArsenal = {
            params ["_arsenalCenter"];
            private _clutterNames = [
				'Ground', 
				'Canopy', 
				'Ejection Seat', 
				'Airplane Crater (Small)'
			];
			private _allMObjects = ((allMissionObjects 'All') + allUnits);
            _allMObjects = _allMObjects select {(_x distance2D _arsenalCenter) < 10};
			private _objectsToDelete = [];
			{
				if ((!alive _x) or (damage _x == 1)) then {
					comment "Delete dead soldiers & destroyed vehicles";
					_objectsToDelete pushBack _x;
					continue;
				};
				private _objName = getText (configFile >> 'cfgVehicles' >> typeOf _x >> 'displayName');
				if (_objName in _clutterNames) then {
					comment "Delete Clutter";
					_objectsToDelete pushBack _x;
					continue;
				};
			}forEach _allMObjects;
            [_objectsToDelete] call MAZ_fnc_deleteObjectServer;
        };

        MAZ_fnc_getArsenalItems = {
            if(isNull MAZ_ArsenalCargo) exitWith {[]};
            private _items = [""];
            _items = _items + (MAZ_ArsenalCargo call BIS_fnc_getVirtualBackpackCargo);
            _items = _items + (MAZ_ArsenalCargo call BIS_fnc_getVirtualItemCargo);
            _items = _items + (MAZ_ArsenalCargo call BIS_fnc_getVirtualWeaponCargo);
            _items = _items + (MAZ_ArsenalCargo call BIS_fnc_getVirtualMagazineCargo);
            _items;
        };

        MAZ_fnc_arsenalFilter = {
            params [["_allowBefore",true,[false]]];
            private _items = call MAZ_fnc_getArsenalItems;
            if(_allowBefore) then {
                _items = _items + (missionNamespace getVariable ["MAZ_LoadoutBeforeArsenal",[]]);
            };
            
            private _itemsRemoved = [];
            "Remove Items";
                private _playerItems = items player + assignedItems player;
                private _weapons = [primaryWeapon player, secondaryWeapon player, handgunWeapon player, binocular player];

                "Remove items and weapons";
                {
                    if !(_x in _items) then {
                        if(_x in assignedItems player) then {
                            player unassignItem _x;
                        };
                        player removeItem _x;
                        _itemsRemoved pushBackUnique _x;
                    };
                }forEach _playerItems;
                {
                    if !(_x in _items) then {
                        player removeWeapon _x;
                        _itemsRemoved pushBackUnique _x;
                    };
                }foreach _weapons;

                "Remove weapon items";
                {
                    if !(_x in _items) then {
                        player removePrimaryWeaponItem _x;
                        _itemsRemoved pushBackUnique _x;
                    };
                }forEach (primaryWeaponItems player);
                {
                    if !(_x in _items) then {
                        player removeSecondaryWeaponItem _x;
                        _itemsRemoved pushBackUnique _x;
                    };
                }forEach (secondaryWeaponItems player);
                {
                    if !(_x in _items) then {
                        player removeHandgunItem _x;
                        _itemsRemoved pushBackUnique _x;
                    };
                }forEach (handgunItems player);

                "Remove clothing items";
                if !(uniform player in _items) then {
                    _itemsRemoved pushBackUnique (uniform player);
                    removeUniform player;
                };
                if !(vest player in _items) then {
                    _itemsRemoved pushBackUnique (vest player);
                    removeVest player;
                };
                if !(backpack player in _items) then {
                    _itemsRemoved pushBackUnique (backpack player);
                    removeBackpackGlobal player;
                };
                if !(headgear player in _items) then {
                    _itemsRemoved pushBackUnique (headgear player);
                    removeHeadgear player;
                };
                if !(goggles player in _items) then {
                    _itemsRemoved pushBackUnique (goggles player);
                    removeGoggles player;
                };

            _itemsRemoved;
        };

        MAZ_fnc_removeExtraLoadouts = {
            if(!isNil "MAZ_customArsenalRespawnEH") then {
                player removeEventHandler ["Respawn",MAZ_customArsenalRespawnEH];
            };
            player setVariable ["MAZ_customLoadoutFromModule",nil];
            if (!isNil "M9SD_EH_arsenalRespawnLoadout") then {
                player removeEventHandler["Respawn", M9SD_EH_arsenalRespawnLoadout];
            };
            private _savedLoadout = missionNamespace getVariable ["bis_fnc_saveInventory_data",[]];
            if(count _savedLoadout == 4) then {
                missionNamespace setVariable ["bis_fnc_saveInventory_data",nil];
            };
        };

        MAZ_fnc_saveLoadout = {
            params ["_display"];
            private _loadoutBefore = getUnitLoadout player;
            private _itemsRemoved = [false] call MAZ_fnc_arsenalFilter;
            private _message = "Your arsenal loadout has been set as your respawn loadout.";
            if((count _itemsRemoved) > 0) then {
                _message = "Some of your items aren't allowed, your loadout has been partially saved.";
            };

            "Add uniform if missing, no indecent exposure";
                private _items = call MAZ_fnc_getArsenalItems;
                if(uniform player == "") then {
                    private _unis = _items select {((_x call BIS_fnc_itemType) # 1) == "Uniform"};
                    player forceAddUniform (selectRandom _unis);
                };

            call MAZ_fnc_removeExtraLoadouts;
            player setVariable ["MAZ_LimitedArsenal_Loadout",getUnitloadout player];
            if(!isNil "MAZ_EH_Respawn_LimitedArsenal") then {
                player removeEventHandler ["Respawn",MAZ_EH_Respawn_LimitedArsenal];
            };
            MAZ_EH_Respawn_LimitedArsenal = player addEventHandler ["Respawn", {
                0 = [] spawn {
                    waitUntil {alive player};
                    sleep 0.1;
                    private _var = player getVariable "MAZ_LimitedArsenal_Loadout";
                    if(!isNil "_var") then {
                        player setUnitLoadout _var;
                    };
                };
            }];
            ["showMessage",[_display,_message]] call bis_fnc_arsenal;
            player setUnitLoadout _loadoutBefore;
        };

        MAZ_fnc_removeLoadout = {
            params ["_display"];
            player setVariable ["MAZ_LimitedArsenal_Loadout",nil];
            if(!isNil "MAZ_EH_Respawn_LimitedArsenal") then {
                player removeEventHandler ["Respawn",MAZ_EH_Respawn_LimitedArsenal];
            };
            ["showMessage",[_display,"Your respawn loadout has been removed."]] call bis_fnc_arsenal;
        };

        MAZ_fnc_arsenalUniformTextures = {
            params ["_display"];
            private _ctrlIcon = _display displayCtrl (930 + 3);
            _ctrlIcon ctrlAddEventHandler ["ButtonClick", {
                params ["_control"];

            }];
        };

        if(!isNil "MAZ_SEH_ArsenalPreOpen_LimitArsenal") then {
            [missionNamespace,"arsenalPreOpen",MAZ_SEH_ArsenalPreOpen_LimitArsenal] call BIS_fnc_removeScriptedEventHandler;
        };
        MAZ_SEH_ArsenalPreOpen_LimitArsenal = [missionNamespace, "arsenalPreOpen", {
            params ["_display","_center"];
            [_center] call MAZ_fnc_removeBodiesNearArsenal;
            MAZ_ArsenalFull = missionNamespace getVariable ["BIS_fnc_arsenal_fullArsenal",false];
            MAZ_ArsenalCargo = missionNamespace getVariable ["BIS_fnc_arsenal_cargo",[]];
            MAZ_LoadoutBeforeArsenal = magazines player + weapons player + items player + assignedItems player + [uniform player, vest player, backpack player, headgear player, goggles player, binocular player] + primaryWeaponItems player + secondaryWeaponItems player + handgunItems player;
        }] call BIS_fnc_addScriptedEventHandler;
        
        if(!isNil "MAZ_SEH_arsenalOpened_LimitArsenal") then {
            [missionNamespace,"arsenalOpened",MAZ_SEH_arsenalOpened_LimitArsenal] call BIS_fnc_removeScriptedEventHandler;
        };
        MAZ_SEH_arsenalOpened_LimitArsenal = [missionNamespace, "arsenalOpened", {
            params ["_display","_togglespace"];

            with uiNamespace do {
                private _face = 15;
                private _speaker = 16;
                private _insignia = 17;

                "Add identity items to lists";
                    private _fnc_getFaceConfig = {
                        private _faces = missionnamespace getvariable ["BIS_fnc_arsenal_faces", [[],[]]];
                        private _faceIndex = _faces select 0 findIf { _this == _x };
                        if (_faceIndex > -1) exitWith { _faces select 1 select _faceIndex };
                        configNull
                    };
                    private _modList = ["","curator","kart","heli","mark","expansion","expansionpremium"];
                    private _fnc_getDLC = {
                        private _dlc = "";
                        private _addons = configsourceaddonlist _this;
                        if (count _addons > 0) then {
                            private _mods = configsourcemodlist (configfile >> "CfgPatches" >> _addons select 0);
                            if (count _mods > 0) then {
                                _dlc = _mods select 0;
                            };
                        };
                        _dlc
                    };
                    private _fnc_addModIcon = {
                        private _dlcName = _this call _fnc_getDLC;
                        if (_dlcName != "") then {
                            _ctrlList lbsetpictureright [_lbAdd,(modParams [_dlcName,["logo"]]) param [0,""]];
                            _modID = _modList find _dlcName;
                            if (_modID < 0) then {_modID = _modList pushback _dlcName;};
                            _ctrlList lbsetvalue [_lbAdd,_modID];
                        };
                    };
                    private _data = missionNamespace getVariable "bis_fnc_arsenal_data";
                    {
                        private _ctrlList = _display displayCtrl (960 + _x);
                        private _list = +(_data # _x);

                        switch (_x) do {
                            case _face: {
                                {
                                    private _xCfg = _x call _fnc_getFaceConfig;
                                    private _displayName = getText (_xCfg >> "displayName");
                                    if (_displayName isEqualTo "") then { _displayName = _x };
                                    private _lbAdd = _ctrlList lbadd _displayName;
                                    _ctrlList lbsetdata [_lbAdd, _x];
                                    _ctrlList lbsettooltip [_lbAdd, format ["%1\n%2",_displayName, _x]];
                                    _xCfg call _fnc_addModIcon;
                                }foreach _list;
                            };
                            case _speaker: {
                                {
                                    private _xCfg = configfile >> "CfgVoice" >> _x;
                                    private _displayName = getText (_xCfg >> "displayName");
                                    if (_displayName isEqualTo "") then { _displayName = _x };
                                    private _lbAdd = _ctrlList lbadd _displayName;
                                    _ctrlList lbsetdata [_lbAdd,_x];
                                    _ctrlList lbsetpicture [_lbAdd,gettext (_xCfg >> "icon")];
                                    _ctrlList lbsettooltip [_lbAdd,format ["%1\n%2",_displayName,_x]];
                                    _xCfg call _fnc_addModIcon;
                                }foreach _list;
                            };
                            case _insignia: {
                                {
                                    private _xCfg = configfile >> "CfgUnitInsignia" >> _x;
                                    private _displayName = getText (_xCfg >> "displayName");
                                    if (_displayName isEqualTo "") then { _displayName = _x };
                                    private _lbAdd = _ctrlList lbadd _displayName;
                                    _ctrlList lbsetdata [_lbAdd, _x];
                                    _ctrlList lbsetpicture [_lbAdd,gettext (_xCfg >> "texture")];
                                    _ctrlList lbsettooltip [_lbAdd,format ["%1\n%2",_displayName,_x]];
                                    _xCfg call _fnc_addModIcon;
                                }foreach _list;
                            };
                        };
                        if(_x == _insignia) then {
                            private _lbAdd = _ctrlList lbadd format [" <%1>",localize "str_empty"];
                            _ctrlList lbsetvalue [_lbAdd,-1];
                        };

                        private _ctrlSort = _display displayctrl (800 + _x);
                        private _sortValues = uinamespace getvariable ["bis_fnc_arsenal_sort",[]];
                        ["lbSort",[[_ctrlSort,_sortValues param [_x,0]],_x]] call bis_fnc_arsenal;

                        private _current = switch (_x) do {
                            case _face: {face player};
                            case _speaker: {speaker player};
                            case _insignia: {player call BIS_fnc_getUnitInsignia};
                        };

                        private _selectIndex = -1;
                        private _isSelected = false;
                        for "_i" from 0 to (lbSize _ctrlList - 1) do {
                            private _listData = _ctrlList lbData _i;
                            if(_listData == _current) then {
                                _isSelected = true;
                                _ctrlList lbSetCurSel _i;
                            };
                        };
                        if(!_isSelected) then {
                            _ctrlList lbSetCurSel -1;
                        };
                    }forEach [_face,_speaker,_insignia];
                "Add identity options";
                    private _tabPositions = [
                        [getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabFace" >> "x"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabFace" >> "y"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabFace" >> "w"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabFace" >> "h")],
                        [getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabVoice" >> "x"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabVoice" >> "y"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabVoice" >> "w"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabVoice" >> "h")],
                        [getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabInsignia" >> "x"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabInsignia" >> "y"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabInsignia" >> "w"),getNumber (configfile >> "RscDisplayArsenal" >> "Controls" >> "TabInsignia" >> "h")]
                    ];
                    
                    private _backgroundOffset = 830;
                    private _iconOffset = 900;
                    private _tabOffset = 930;

                    {
                        private _tab = _x;
                        private _posIndex = _forEachIndex;
                        {
                            if(_tab == _speaker && _x == _backgroundOffset) then {continue};
                            private _ctrl = _display displayCtrl (_tab + _x);
                            _ctrl ctrlShow true;
                            _ctrl ctrlEnable true;
                            _ctrl ctrlAddEventHandler ["ButtonClick", format ["with uinamespace do {['TabSelectLeft',[ctrlParent (_this select 0),%1]] call bis_fnc_arsenal;};",_tab]];
                            _ctrl ctrlAddEventHandler ["MouseZChanged", "with uinamespace do {['MouseZChanged',_this] call bis_fnc_arsenal;};"];
                            _ctrl ctrlSetPosition (_tabPositions # _posIndex);
                            _ctrl ctrlCommit 0;
                        }forEach [_backgroundOffset,_iconOffset,_tabOffset];
                    }forEach [_face,_speaker,_insignia];

                "Swap to weapon when selected";

                    private _primary = 0;
                    private _secondary = 1;
                    private _handgun = 2; 
                    private _bino = 9;
                    {
                        private _tab = _x;
                        private _index = _forEachIndex;
                        {
                            private _ctrl = _display displayCtrl (_tab + _x);
                            private _weaponType = ["primaryWeapon","secondaryWeapon","handgunWeapon","binocular","primaryWeapon"] # _index;
                            private _actionType = ["primaryWeapon","secondaryWeapon","handGunOn","Binoculars","Salute"] # _index;
                            _ctrl ctrlAddEventHandler ["ButtonClick", format ["
                                private _type = %1 player;
                                if(_type != '') then {
                                    player selectWeapon _type;
                                };
                                private _action = '%2';
                                if (simulationenabled player) then {player playactionnow _action;} else {player switchaction _action;};
                            ",_weaponType,_actionType]];
                        }forEach [_backgroundOffset,_iconOffset,_tabOffset];
                    }forEach [_primary,_secondary,_handgun,_bino,_insignia];

                "Add warning text at top";
                    private _text = _display ctrlCreate ["RscStructuredText",-1];
                    private _textWidth = 0.5;
                    _text ctrlSetPosition [0.5-(_textWidth/2),-0.4,_textWidth,0.15];
                    _text ctrlSetStructuredText parseText ("<t align='center' size='1.5' color='#FFD966'>[ Limited Arsenal ]</t><br/><t align='center'>Only items available within this arsenal can be used. Extra items will be removed when the arsenal is closed.</t>");
                    _text ctrlSetBackgroundColor [0,0,0,0.7];
                    _text ctrlCommit 0;

                    [_display,_text] spawn {
                        params ["_display","_text"];
                        while {!isNull _display} do {
                            waitUntil {!(ctrlshown (_display displayctrl 44046))};
                            _text ctrlSetFade 1;
                            _text ctrlCommit 0;
                            waitUntil {ctrlshown (_display displayctrl 44046)};
                            _text ctrlSetFade 0;
                            _text ctrlCommit 0;
                        };
                    };

                "Add respawn loadout buttons";
                    private _exportButton = _display displayCtrl 44148;
                    _exportButton ctrlSetText "Set Loadout";
                    _exportButton ctrlSetTooltip "Sets current loadout as a respawn loadout.\nThis loadout will be given back to you when you respawn.";
                    _exportButton ctrlRemoveAllEventHandlers "ButtonClick";
                    _exportButton ctrlAddEventHandler ["ButtonClick", {
                        [ctrlParent (_this select 0)] call MAZ_fnc_saveLoadout;
                    }];
                    private _importButton = _display displayCtrl 44149;
                    _importButton ctrlSetText "Reset Loadout";
                    _importButton ctrlSetTooltip "Deletes your saved respawn loadout.\nWhen you respawn you won't have a respawn loadout unless you saved one with another arsenal.";
                    _importButton ctrlRemoveAllEventHandlers "ButtonClick";
                    _importButton ctrlAddEventHandler ["ButtonClick", {
                        [ctrlParent (_this select 0)] call MAZ_fnc_removeLoadout;
                    }];

                "Add uniforms stuff";
                    '[_display] call (missionNamespace getVariable "MAZ_fnc_arsenalUniformTextures")';

                "Tell player if they have special, cool items";
                    if(false) then {
                        ["showMessage",[_display,"You've found some items that aren't in this arsenal, you'll keep them when you exit."]] call bis_fnc_arsenal;
                    };
            };
        }] call BIS_fnc_addScriptedEventHandler;

        if(!isNil "MAZ_SEH_ArsenalClosed_LimitArsenal") then {
            [missionNamespace,"arsenalClosed",MAZ_SEH_ArsenalClosed_LimitArsenal] call BIS_fnc_removeScriptedEventHandler;
        };
        MAZ_SEH_ArsenalClosed_LimitArsenal = [missionNamespace, "arsenalClosed", {
            "Remove items";
                if(!MAZ_ArsenalFull) then {
                    private _itemsRemoved = [true] call MAZ_fnc_arsenalFilter;
                    "Error messages";
                    if(count _itemsRemoved != 0) then {
                        private _errorString = "Items removed: ";
                        {
                            if(_x == "") then {continue};
                            _errorString = _errorString + ([_x] call MAZ_fnc_getItemDisplayName);
                            if(_forEachIndex == (count _itemsRemoved) - 1) then {
                                _errorString = _errorString + ".";
                            } else {
                                _errorString = _errorString + ", ";
                            };
                        }forEach _itemsRemoved;

                        [_errorString] spawn {
                            params ["_errorString"];
                            playSound "addItemFailed";
                            [
                                (format ["<t align='center' size='2.0' color='#FFD966'>[ Limited Arsenal ]</t><br/><t align='center'>Some items you had weren't in the arsenal and have been removed!</t><br/><t align='center'>%1</t>",_errorString]),
                                "Items Removed Warning"
                            ] call BIS_fnc_guiMessage;
                        };
                    };
                };

            "Reset arsenal variables";
                MAZ_ArsenalFull = nil;
                MAZ_ArsenalCargo = objNull;
                MAZ_LoadoutBeforeArsenal = nil;

            "Lower weapon";
                player action ["WeaponOnBack", player];
        }] call BIS_fnc_addScriptedEventHandler;
    };
    [] call MAZ_fnc_limitArsenals;
    [] spawn {
		waitUntil {uiSleep 0.1; !isNil "MAZ_EP_fnc_addDiaryRecord"};
		["Limited Arsenals", "Any arsenal you open is restricted to whatever items are available within it. If every item is available, you can use everything, otherwise when you close the arsenal you'll lose out on your meta-gamer gear. Sorry, not sorry!"] call MAZ_EP_fnc_addDiaryRecord;
	};
	[] spawn {
		waitUntil {uiSleep 0.1; !isNil "MAZ_EP_fnc_createNotification"};
		[
			"Limited Arsenals System has been loaded! Meta-gamers beware!",
			"System Initialization Notification"
		] spawn MAZ_EP_fnc_createNotification;
	};
}) splitString "";

_value deleteAt (count _value - 1);
_value deleteAt 0;

_value = _value joinString "";
_value = _value + "removeMissionEventhandler ['EachFrame',_thisEventHandler];";
_value = _value splitString "";

missionNamespace setVariable [_varName,_value,true];

[[_varName], {
	params ["_ding"];
	private _data = missionNamespace getVariable [_ding,[]];
	_data = _data joinString "";
	addMissionEventhandler ["EachFrame", _data];
}] remoteExec ['spawn',0,_myJIPCode];