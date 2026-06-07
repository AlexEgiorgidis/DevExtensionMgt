namespace GetInstalledExtensions.Core;

page 60000 "Dev. Extension Management"
{
    ApplicationArea = All;
    Caption = 'Smarter-Dev. Extension Management';
    PageType = List;
    SourceTable = "Installed Extension List";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the value of the Name field.', Comment = '%';
                }
                field(Publisher; Rec.Publisher)
                {
                    ToolTip = 'Specifies the value of the Publisher field.', Comment = '%';
                }
                field("Published As"; Rec."Published As")
                {
                    ToolTip = 'Specifies the value of the Publishes As field.', Comment = '%';
                }
                field("App ID"; Rec."App ID")
                {
                    ToolTip = 'Specifies the value of the App ID field.', Comment = '%';
                }
                field("Package ID"; Rec."Package ID")
                {
                    ToolTip = 'Specifies the value of the Package ID field.', Comment = '%';
                }
                field("Select App Record"; Rec."Select App Record")
                {
                    ToolTip = 'Specifies the value of the Select App Record field.', Comment = '%';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(ClearSelected_Promoted; ClearSelected)
            { }
            actionref(LoadList_Promoted; LoadList)
            { }
            actionref(DownloadApp_Promoted; DownLoadApp)
            { }
            actionref(DownLoadAppMultiple_Promoted; DownLoadAppMultiple)
            { }
            actionref(CreateDepMsg_Promoted; CreateDependecyMessage)
            { }
        }
        area(Processing)
        {
            action(LoadList)
            {
                Caption = 'Refresh List';
                Image = WorkCenterLoad;

                trigger OnAction()
                begin
                    Rec.ClearInstalledApps();
                    Rec.GetInstalledApps();
                    ResetPageFilters();
                end;
            }
            action(DownLoadApp)
            {
                Caption = 'Download App file';
                Image = Download;

                trigger OnAction()
                begin
                    Rec.DownloadAppSourceFile(Rec);
                    ResetPageFilters();
                end;
            }
            action(DownLoadAppMultiple)
            {
                Caption = 'Download App file-Multiple';
                Image = SendToMultiple;

                trigger OnAction()
                begin
                    Rec.GetExtensionSource(Rec);
                    ResetPageFilters();
                end;
            }
            action(CreateDependecyMessage)
            {
                Caption = 'Create Dependecy for app.json';
                Image = CreateForm;

                trigger OnAction()
                begin
                    Rec.CreateDependecyMessage();
                    ResetPageFilters();
                end;
            }
            action(ClearSelected)
            {
                Caption = 'Clear Selected';
                Image = ClearFilter;

                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.ModifyAll("Select App Record", false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.ClearInstalledApps();
        Rec.GetInstalledApps();
        ResetPageFilters();
    end;

    local procedure ResetPageFilters()
    begin
        if not Rec.IsEmpty then begin
            Rec.Reset();
            Rec.ModifyAll("Select App Record", false);
            Rec.FindFirst();
        end;
    end;
}
