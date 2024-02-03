unit TwilioClient;

interface

uses
  System.Classes,
  System.JSON,
  System.StrUtils,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.Net.URLClient;

type

  TTwilioClientResponse = record
    Success: boolean;
    ResponseData: TJSONValue;
    HTTPResponse: IHTTPResponse;
  end;

  TTwilioClient = Class
  private
    FUserName: string;
    FPassword: string;
    FAccountSid: string;
    FHttpClient: TNetHttpClient;
    FRequest: TNetHTTPRequest;

  protected
    procedure AuthEventHandler(const Sender: TObject;
      AnAuthTarget: TAuthTargetType; const ARealm, AURL: string;
      var AUserName, APassword: string; var AbortAuth: Boolean;
      var Persistence: TAuthPersistenceType); virtual;

  public
    constructor Create(UserName: string; Password: string;
      AccountSid: string = ''); virtual;

    destructor Destroy; override;

    function Post(resource: string; params: TStrings; domain: string = 'api';
      version: string = '2010-04-01'; prefix: string = '/Accounts/{sid}')
      : TTwilioClientResponse;

    function Get(resource: string; params: TStrings; domain: string = 'api';
      version: string = '2010-04-01'; prefix: string = '/Accounts/{sid}')
      : TTwilioClientResponse;

    function Del(resource: string; sid: string; domain: string = 'api';
      version: string = '2010-04-01'; prefix: string = '/Accounts/{sid}')
      : TTwilioClientResponse;
end;

implementation

constructor TTwilioClient.Create(UserName: string; Password: string;
  AccountSid: string = '');
begin
  FUserName := UserName;
  FPassword := Password;
  if AccountSid = '' then
    FAccountSid := UserName
  else
    FAccountSid := AccountSid;
  FHttpClient := TNetHttpClient.Create(nil);
  FHttpClient.OnAuthEvent := AuthEventHandler;
  FRequest := TNetHTTPRequest.Create(nil);
  FRequest.Client := FHttpClient;
end;

function TTwilioClient.Del(resource, sid, domain, version,
  prefix: string): TTwilioClientResponse;
var
  url: String;
begin
  url := 'https://' + domain + '.twilio.com/' + version + prefix + '/' +
    resource + '/'+sid+'.json';
  if ContainsText(url, '{sid}') then
    url := ReplaceText(url, '{sid}', FAccountSid);
  Result.HTTPResponse := FRequest.Delete(url);
  Result.Success := (Result.HTTPResponse.StatusCode >= 200) and
    (Result.HTTPResponse.StatusCode <= 299) and
    (Result.ResponseData <> nil);
end;

destructor TTwilioClient.Destroy;
begin
  inherited;
  FRequest.Free;
  FHttpClient.Free;
end;

function TTwilioClient.Get(resource: string; params: TStrings; domain, version,
  prefix: string): TTwilioClientResponse;
var
  url: String;
begin
  url := 'https://' + domain + '.twilio.com/' + version + prefix + '/' + resource + '.json';
  if ContainsText(url, '{sid}') then
    url := ReplaceText(url, '{sid}', FAccountSid);
  Result.HTTPResponse := FRequest.Get(url);
  Result.ResponseData := TJSONObject.ParseJSONValue(Result.HTTPResponse.ContentAsString(TEncoding.UTF8));
  Result.Success := (Result.HTTPResponse.StatusCode >= 200) and
    (Result.HTTPResponse.StatusCode <= 299) and
    (Result.ResponseData <> nil);
end;

function TTwilioClient.Post(resource: string; params: TStrings;
  domain: string = 'api'; version: string = '2010-04-01';
  prefix: string = '/Accounts/{sid}'): TTwilioClientResponse;
var
  url: String;
begin
  url := 'https://' + domain + '.twilio.com/' + version + prefix + '/' +
    resource + '.json';
  if ContainsText(url, '{sid}') then
    url := ReplaceText(url, '{sid}', FAccountSid);
  Result.HTTPResponse := FRequest.Post(url, params);
  Result.ResponseData := TJSONObject.ParseJSONValue(
    Result.HTTPResponse.ContentAsString(TEncoding.UTF8));
  Result.Success := (Result.HTTPResponse.StatusCode >= 200) and
    (Result.HTTPResponse.StatusCode <= 299) and
    (Result.ResponseData <> nil);
end;

procedure TTwilioClient.AuthEventHandler(const Sender: TObject;
  AnAuthTarget: TAuthTargetType; const ARealm, AURL: string;
  var AUserName, APassword: string; var AbortAuth: Boolean;
  var Persistence: TAuthPersistenceType);
begin
  if AnAuthTarget = TAuthTargetType.Server then
  begin
    AUserName := FUserName;
    APassword := FPassword;
  end;
end;

end.
