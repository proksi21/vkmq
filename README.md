# vkmq
### Установка
Загрузите архив с последней версией **vkmq** на свой сервер

    wget https://github.com/proksi21/vkmq/releases/download/v0.1/vkmq.zip
Распакуйте архив

    unzip vkmq.zip
Распакованный бинарный файл готов к работе.
### Запуск

    ./vkmq -a "ADDRESS" -s "SECRET_TOKEN" -c "CONFIRM_TOKEN"
*ADDRESS* - адрес вашего сервера, например 12.12.12.45:80

*SECRET_TOKEN* - токен для доступа к vkmq, придумайте его сами, и посложнее.

*CONFIRM_TOKEN* - код подтверждения, который нужно вернуть vk при настройке сервера для API
### Использование
Для доступа к vkmq отправьте GET запрос на 

***"Ваш_адрес_сервера/vkmq?SECRET_TOKEN".***

В ответ на данный запрос vkmq вернет json-объект в формате

***{"user_id":"text"}***
