namespace GetInstalledExtensions.Core;
using System.Apps;
using System.Utilities;
using System.IO;

table 60000 "Installed Extension List"
{
    Caption = 'Installed Extension List';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        field(2; "Package ID"; Guid)
        {
            Caption = 'Package ID';
            Editable = false;
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(4; Publisher; Text[250])
        {
            Caption = 'Publisher';
            Editable = false;
        }
        field(5; "Version Major"; Integer)
        {
            Caption = 'Version Major';
        }
        field(6; "Version Minor"; Integer)
        {
            Caption = 'Version Minor';
        }
        field(7; "Version Build"; Integer)
        {
            Caption = 'Version Build';
        }
        field(8; "Version Revision"; Integer)
        {
            Caption = 'Version Revision';
        }
        field(16; "Published As"; Option)
        {
            Caption = 'Published As';
            OptionCaption = 'Global, PTE, Dev';
            OptionMembers = "Global","PTE","Dev";
        }
        field(50000; "Select App Record"; Boolean)
        {
            Caption = 'Select App Record';
            Editable = true;
        }
    }
    keys
    {
        key(PK; "App ID")
        {
            Clustered = true;
        }
    }

    internal procedure ClearInstalledApps()
    begin
        Rec.Reset();
        Rec.DeleteAll(false);
    end;

    internal procedure GetInstalledApps()
    var
        NAVAppInstalledApp: record "NAV App Installed App";
        IsMicrosoftExtTxt: label 'Microsoft', Locked = true;
    begin
        NAVAppInstalledApp.Reset();
        if NAVAppInstalledApp.FindSet(false) then begin
            repeat
                if NAVAppInstalledApp.Publisher <> IsMicrosoftExtTxt then begin
                    Rec.Init();
                    Rec.TransferFields(NAVAppInstalledApp, true);
                    Rec.Validate("Select App Record", false);
                    Rec.Insert(false);
                end;
            until NAVAppInstalledApp.Next() = 0;
        end;
    end;

    internal procedure UninstallApp()
    var
        ExtensionManagement: codeunit "Extension Management";
        ConfirmMgt: codeunit "Confirm Management";
        UnistallQst: label 'Are you sure you want to Uninstall %1 by %2 ?', comment = '%1 is the Extension Name, %2 is the Publisher';
        DeleteAppDateQst: label 'Do you want to Clear the Extension Data?';
    begin
        Rec.Reset();
        Rec.SetRange("Select App Record", true);
        if Rec.FindSet(false) then begin
            repeat
                CheckIfMicrosoftExt(Rec);
                CheckPublishType(Rec);
                Clear(ExtensionManagement);
                if not ConfirmMgt.GetResponse(StrSubstNo(UnistallQst, Rec.Name, Rec.Publisher), false) then
                    exit;
                if ConfirmMgt.GetResponse(DeleteAppDateQst, false) then begin
                    if not ExtensionManagement.UninstallExtensionAndDeleteExtensionData(Rec."Package ID", false) then
                        message(GetLastErrorText());
                end else begin
                    if not ExtensionManagement.UninstallExtension(Rec."Package ID", false) then
                        message(GetLastErrorText());
                end;
            until Rec.Next() = 0;
        end;
    end;

    internal procedure UnPublishApp()
    var
        ExtensionManagement: codeunit "Extension Management";
        ConfirmMgt: codeunit "Confirm Management";
        UnPublishQst: label 'Do you want to UnPublish %1 %3 ?', comment = '%1 is the Extension Name, %2 is the Publisher';
    begin
        Rec.Reset();
        Rec.SetRange("Select App Record", true);
        if Rec.FindSet(false) then begin
            repeat
                CheckIfMicrosoftExt(Rec);
                Clear(ExtensionManagement);
                if not ConfirmMgt.GetResponse(StrSubstNo(UnPublishQst, Rec.Name, Rec.Publisher), false) then
                    exit;
                if not ExtensionManagement.UnpublishExtension(Rec."Package ID") then
                    message(GetLastErrorText());
            until Rec.Next() = 0;
        end;
    end;

    internal procedure DownloadAppSourceFile(var p_Rec: Record "Installed Extension List" temporary)
    var
        ExtensionManagement: codeunit "Extension Management";
    begin
        ExtensionManagement.DownloadExtensionSource(p_Rec."Package ID");
    end;

    internal procedure GetExtensionSource(var p_Rec: Record "Installed Extension List" temporary)
    var
        ExtensionManagement: codeunit "Extension Management";
        ExtensionSourceTempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        AppFileOutStream: OutStream;
        AppFileInStream: InStream;
        ZipOutStream: OutStream;
        ZipInStream: InStream;
        FullFileName: Text;
        ZipFileName: Text[50];
    begin
        ZipFileName := 'AppFiles_.zip';
        DataCompression.CreateZipArchive();
        p_Rec.Reset();
        p_Rec.SetRange("Select App Record", true);
        if p_Rec.FindSet(false) then begin
            repeat
                ExtensionSourceTempBlob.CreateOutStream(AppFileOutStream);
                ExtensionManagement.GetExtensionSource(p_Rec."Package ID", ExtensionSourceTempBlob);
                ExtensionSourceTempBlob.CreateInStream(AppFileInStream);
                FullFileName := p_Rec.Name + '.app';
                DataCompression.AddEntry(AppFileInStream, FullFileName);
            until p_Rec.Next() = 0;
        end;
        ExtensionSourceTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        ExtensionSourceTempBlob.CreateInStream(ZipInStream);
        DownloadFromStream(ZipInStream, '', '', '', ZipFileName);
    end;

    internal procedure CreateDependecyMessage()
    var
        DependecyMsg: Text;
        BuildTxt: text;
        RecordsFound, RecordProcessed : integer;
    begin
        DependecyMsg := '';
        RecordsFound := 0;
        RecordProcessed := 0;
        BuildTxt := '{\' +
                    '"id": "%1",\' +
                    '"name": "%2",\' +
                    '"version": "%3",\' +
                    '"publisher": "%4"\' +
                    '}';
        Rec.Reset();
        Rec.SetRange("Select App Record", true);
        if Rec.FindSet(false) then begin
            RecordsFound := Rec.Count();
            repeat
                DependecyMsg := DependecyMsg + StrSubstNo(BuildTxt, RemoveSpecialChar(Rec."App ID"),
                                                          Rec.Name,
                                                          GetAppVersion(Rec),
                                                          Rec.Publisher);
                RecordProcessed += 1;
                if RecordProcessed < RecordsFound then
                    DependecyMsg := DependecyMsg + ',\';
            until Rec.Next() = 0;
        end;

        if DependecyMsg <> '' then
            message(DependecyMsg);
    end;

    local procedure CheckIfMicrosoftExt(var p_Rec: Record "Installed Extension List" temporary)
    var
        IsMicrosoftExtTxt: label 'Microsoft', Locked = true;
        IsMicrosoftExtErr: label 'Can not uninstall a Microsoft extension', Locked = true;
    begin
        if p_Rec.Publisher = IsMicrosoftExtTxt then
            error(IsMicrosoftExtErr);
    end;

    local procedure CheckPublishType(var p_Rec: Record "Installed Extension List" temporary)
    var
        IsNotPTEErr: label 'Can not uninstall an extension of type %1', Locked = true;
    begin
        if p_Rec."Published As" = p_Rec."Published As"::Global then
            error(IsNotPTEErr, Format(p_Rec."Published As"));
    end;

    local procedure GetAppVersion(var p_Rec: Record "Installed Extension List" temporary): Text
    var
        AppVersion: text;
    begin
        AppVersion := Format(p_Rec."Version Major") + '.' +
                      Format(p_Rec."Version Minor") + '.' +
                      Format(p_Rec."Version Build") + '.' +
                      Format(p_Rec."Version Revision");
        exit(AppVersion);
    end;

    local procedure RemoveSpecialChar(p_AppID: text): Text
    var
        AppID: text;
    begin
        AppID := p_AppID;
        AppID := DelChr(AppID, '=', '{');
        AppID := DelChr(AppID, '=', '}');
        exit(AppID);
    end;
}
