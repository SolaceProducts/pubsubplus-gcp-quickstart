from __future__ import print_function
import httplib2
import os

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

import json

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/groupssettings-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/apps.groups.settings'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Groups Settings API Python Quickstart'


def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'groupssettings-python-quickstart.json')

    store = Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
        else: # Needed only for compatibility with Python 2.6
            credentials = tools.run(flow, store)
        print('Storing credentials to ' + credential_path)
    return credentials

def main():
    """Shows basic usage of the Google Admin-SDK Groups Settings API.

    Creates a Google Admin-SDK Groups Settings API service object and outputs a
    group's settings identified by the group's email address.
    """
    credentials = get_credentials()
    http = credentials.authorize(httplib2.Http())
    service = discovery.build('groupssettings', 'v1', http=http)

    groupEmail = \
        raw_input('Enter the email address of a Google Group in your domain: ')
    try:
        results = service.groups().get(groupUniqueId=groupEmail,
            alt='json').execute()
        print(json.dumps(results, indent=4))
    except:
        print('Unable to read group: {0}'.format(groupEmail))
        raise

if __name__ == '__main__':
    main()
