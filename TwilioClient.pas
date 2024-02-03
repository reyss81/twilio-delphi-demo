unit TwilioClient;

interface

uses
  System.Classes,
  System.DateUtils,
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

    function twilioDateConvert(twilioDate: string): TDateTime;
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

function TTwilioClient.twilioDateConvert(twilioDate: string): TDateTime;
const
  iFormat= 'ddd, DD MM YYYY HH:NN:SS +ZZZZ';
  iMonths: array[1..12] of string= ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

var
  AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word;
  aPos: Integer;

  procedure InitVars;
  begin
    AYear := 1;
    AMonth := 1;
    ADay := 1;
    AHour := 0;
    AMinute := 0;
    ASecond := 0;
    AMilliSecond := 0;
  end;

  function GetPart(const iPart: Char): Word;
  var
    aYCnt: Integer;
  begin
    Result := 0;
    aYCnt := 0;

    while (aPos <= High(iFormat)) and (iFormat.Chars[aPos + aYCnt] = iPart) do
      inc(aYCnt);

    Result := StrToInt(twilioDate.Substring(aPos, aYCnt));

    aPos := aPos + aYCnt;
  end;

begin
  InitVars;

  for aPos:= 1 to 12 do
  begin
    if pos(iMonths[aPos],twilioDate)>0 then
    begin
      if aPos<10 then
        twilioDate:= StringReplace(twilioDate,iMonths[aPos],'0'+IntToStr(aPos),[rfReplaceAll, rfIgnoreCase])
      else
        twilioDate:= StringReplace(twilioDate,iMonths[aPos],IntToStr(aPos),[rfReplaceAll, rfIgnoreCase]);
      break;
    end;
  end;

  aPos := 0;
  while aPos <= High(iFormat) do
  begin
    case iFormat.Chars[aPos] of
      'Y':
        AYear := GetPart('Y');
      'M':
        AMonth := GetPart('M');
      'D':
        ADay := GetPart('D');
      'H':
        AHour := GetPart('H');
      'N':
        AMinute := GetPart('N');
      'S':
        ASecond := GetPart('S');
      'Z':
        AMilliSecond := GetPart('Z');
    else
      inc(aPos);
    end;
  end;

  Result := EncodeDateTime(AYear, AMonth, ADay, AHour, AMinute, ASecond,
    AMilliSecond);
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
