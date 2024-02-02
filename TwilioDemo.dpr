program TwilioDemo;
{$APPTYPE CONSOLE}
{$R *.res}
uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.Net.HttpClient,
  TwilioClient in 'TwilioClient.pas';

var
  client: TTwilioClient;
  allParams: TStringList;
  response: TTwilioClientResponse;
  json: TJSONValue;
  jsonArray: TJSONArray;
  fromPhoneNumber: string;
  toPhoneNumber: string;
  jsonValue: TJSONValue;
  sms_sid: string;
begin
  try
    // Create environment variables (named below) with your Twilio credentials
    // Run as administrator to get access to the enviroment variables
    client := TTwilioClient.Create(GetEnvironmentVariable('TWILIO_ACCOUNT_SID'),
                                   GetEnvironmentVariable('TWILIO_AUTH_TOKEN'));
    toPhoneNumber := '5555555555';     //replace for a valid phone number...for trials, this needs to be your mobile
    fromPhoneNumber := '+5555555555'; //replace for your twilio virtual phone number
    // Make a phone call
    Writeln('----- Phone Call -----');
    allParams := TStringList.Create;
    allParams.Add('From=' + fromPhoneNumber);
    allParams.Add('To=' + toPhoneNumber);
    allParams.Add('Url=http://demo.twilio.com/docs/voice.xml');
    response := client.Post('Calls', allParams);
    if response.Success then
      Writeln('Call SID: ' + response.ResponseData.GetValue<string>('sid'))
    else if response.ResponseData <> nil then
      Writeln(response.ResponseData.ToString)
    else
      Writeln('HTTP status: ' + response.HTTPResponse.StatusCode.ToString);
    // Send a text message
    Writeln('----- SMS -----');
    allParams := TStringList.Create;
    allParams.Add('From=' + fromPhoneNumber);
    allParams.Add('To=' + toPhoneNumber);
    allParams.Add('Body=Hola Mundo desde Delphi');
    response := client.Post('Messages', allParams);
    if response.Success then
      Writeln('Message SID: ' + response.ResponseData.GetValue<string>('sid'))
    else if response.ResponseData <> nil then
      Writeln(response.ResponseData.ToString)
    else
      Writeln('HTTP status: ' + response.HTTPResponse.StatusCode.ToString);
    // GET all messages from the Messages resource
    Writeln('----- SMS -----');
    response := client.Get('Messages',allParams);
    if response.Success then
    begin
      jsonArray := response.ResponseData.GetValue<TJSONArray>('messages');
      for jsonValue in jsonArray do
      begin
         Writeln('Message SID: ' + jsonValue.GetValue<string>('sid'));
         Writeln('Message Body: ' + jsonValue.GetValue<string>('body'));
      end;
    end else
      if response.ResponseData <> nil then
        Writeln(response.ResponseData.ToString)
      else
        Writeln('HTTP status: ' + response.HTTPResponse.StatusCode.ToString);
    // delete a message
    writeln;
    write('Enter de sms SID: ');
    readln(sms_sid);
    response := client.Del('Messages',sms_sid);
    if response.Success then
      Writeln(sms_sid + ' deleted')
    else
      Writeln('HTTP status: ' + response.HTTPResponse.StatusCode.ToString);
  finally
    client.Free;
  end;
  Writeln('Press ENTER to exit.');
  Readln;
end.
