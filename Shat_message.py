from httplib2 import Http
from json import dumps

#
# Hangouts Chat incoming webhook quickstart
#
def main():
    url = 'https://chat.googleapis.com/v1/spaces/AAAA0yYN5pI/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=xlzpEguXD5smrp4G3C6QHJvmobPCGfWkyIUWvPNJAYk%3D'
    bot_message = {
        'text' : '<users/all> *Matthew* is *unable* to awnser the phone!!!'}

    message_headers = { 'Content-Type': 'application/json; charset=UTF-8'}

    http_obj = Http()

    response = http_obj.request(
        uri=url,
        method='POST',
        headers=message_headers,
        body=dumps(bot_message),
    )

    print(response)

if __name__ == '__main__':
    main()
