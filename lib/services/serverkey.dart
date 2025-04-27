import 'package:googleapis_auth/auth_io.dart';

class get_server_key {
  Future<String> server_token() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "apps-d19d9",
        "private_key_id": "4c3d6401b7cbe58e81133c18f073493aa909275a",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDfWdo1+l7QBXgO\nwfrRg23h7d53SIEaP5NlYwYWKj59vxUXAXUy8gTSGLg2Ev1ZcsHVgCUD6+oBREOa\nauqwA63fR1ELju/OflF1Np4Nt9tE8QpmrTADc+JFyZiq+BCmSIEnTK8ZrNOL36ZK\nhIXMve0BO6YXPU0VzeGsQ+AG/02pbjupyf5EDrfrTC/MOox43ILeRPqGJawkM9yO\nW9cms0dd6neGEthbY7+FtQbecvUSfot/nHV4Tyii+G2cpUNSLHkbfxrG8TAUZx2B\n9ZGnuq2U9hwFNWnQk6fNR9T/uQe3hxkKhUQSDKxfz7eXjY6JxzAsEgKsraVHCI5s\nkep3GG+nAgMBAAECggEAQkWw/884jtTwmMBqIfyzgBRKrG4xEI7It464YZ9LR5iJ\nM3hVRDaXw5deIX1k+0OXzDfnw9AecR3GSW1sEaolz1ij7aAN++FzXipEn6FsSHqV\nMX41/vBFtZtp12Ef35cn63dPhXjIlHpaJ0ZHRUcdqf3+/GpOEygxzCGfubPLYXgr\n+Qn7BVZeUb4jKXeIGntX50SxFfzkUIlXMbnVV2ILGCSsLrlAlp0AFWVhC0q+aTy/\nCGVHtSHhc6+0sPyC0AENdCW2xRwaqs7se2oIazampwxIiFwmaOlZFxqtRQSo5FaE\nirBz6DMuE9ExKnNZHh9wYSXnVBfSC0N3yb3VuB578QKBgQD2M0ibEYWyknNNVSbM\naFqOAYdPTuiubcl8vPJ8XZfliMuLQmVx66yGa3e4RVzmt0ANY/JgYMVxz4cSC1zA\neOMjMxBH53WUcKIot4uifUZcuH4uR9IzzS/18ZLyQfBBJQ9G7LW3fjZOY59l3SRd\n7VNrgxmKi6+8nLFFO1xzBN+9+wKBgQDoPb1xooWaQ6VmHfF5oiR0vFkWDRyTYD6D\nX/imrU+xNoQaKhD8mCL61BQzfwyblk/XD0/S+T0CWBncQZGNIwKmAyRMtthefbPZ\n+6SSZCd2W63vhY9138ud14yzxhrzXxt45ZWkokchyHzRvvxFaxPRSlbahYdEYepZ\nAA6V1LDBRQKBgQDkP0syqB4BHZDTwvvDSYOaX4RoXEmPXK0NfcZ40fQ+koHRy25t\nHQbHX96P8Y5dPsqdH2nXPCAQkUsxyWLl9azuNysC3my9f2Z2xSMpM2cGEuy4T1Fr\nQPET3DBVdBge7RKquE0HnnUOW4GtWEWc5qcN527IaRQ1kjcubggZgg1D/QKBgGFm\ns3NbNClUwaOoX0QiKqQC8mH7McblkJJMx94vxcKPGKxYhDNMIy+LjsViPYlrayTJ\nOTNEcL/w7zefEEpfKpcxriG2ddx7X9jGX2k+NAbBwJs6KsbHC4CxjENBjMARXVZB\nA5e+r5KNoTvem7MJi5A1W2PeqLKXVk/pZDSWtWL5AoGBAOqhh6VcrqL5YIeUprxV\nqf2trOP136KUuBv6f35KountSeTLV7o8VCdM9oKwaBQFq2EQ4Nz9uTIpYutLs1m1\nlJzjRvpEgzqhMJ03k9dmhf31Q4+9CTvFf04v1AAVNF2G14Xlby7iGKTYYxHhoEIO\nIawe2922gl0bmG31BFSFVJTi\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@apps-d19d9.iam.gserviceaccount.com",
        "client_id": "105609221518825856000",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40apps-d19d9.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );
    final accessserverkey = client.credentials.accessToken.data;
    return accessserverkey;
  }
}
