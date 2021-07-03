#  Tournament – Ein Programm für Tischtennisturniere

## Installation
### Datenbank
Vor dem ersten Start von Tournament muss die Datenbank (also das Programm Postgres) installiert werden. Tournament verwendet das Programm Docker um die Datenbank vom Rest des Systems zu isolieren. Um Docker auf dem Mac zu installieren gehe zur Webseite

[https://docs.docker.com/docker-for-mac/install/](https://docs.docker.com/docker-for-mac/install/)

und befolge die Instruktionen. Beim letzten Update dieses Dokuments hies das:

1. Download des stable channel image von Docker-for-Mac
2. Auf dem geladenen .dmg-image befindet sich Docker.app, dieses muss in den Applications (resp. Programme-) Ordner verschoben werden.
3. Starte Docker.app und authorisiere es mit einem System-Passwort, es braucht erweiterte Kompetenzen um die Netzwerk-Verbindungen sauber herzustellen.

Nun brauchen wir nur noch das Postgres-image. Dazu benötigen wir ein Terminal. Dort muss der folgende Befehl ausgeführt werden:

    docker pull postgres
    
Dieser Befehl bezieht die aktuelle Version der Datenbank. Nach Abschluss des Downloads sollte der Befehl

    docker images

die Zeilen

    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    postgres            latest              4860bdf1a517        4 days ago          287MB

(oder so ähnlich) enthalten.

### Installation des Programms
Das Programm `Tournament` muss nun aus der Dropbox in den lokalen `Programme`-Ordner verschoben werden.
### Start
Nun kann das Programm mit einem Doppelklick auf `Tournament.app` gestartet werden. Beim Start überprüft `Tournament` ob die Datenbank schon erreichbar ist und startet sie falls notwendig. Danach muss man das Programm beenden und nach ein paar Sekunden neu starten. Beim nächsten Start werden die Datenbank-Tabellen erzeugt. Dies geschieht automatisch und der Benutzer spürt (ausser evtl. einer kleinen Verzögerung) nichts davon.

Ab jetzt kann mit dem Programm `Tournament` normal gearbeitet werden.
## Backup
Um die Postgres-Datenbank in einem Docker-Container auf eine neue Major-Version upzudaten muss man die Datenbank manchmal exportieren und wieder importieren. Dies kann man etwa mit den folgenden Befehlen erreichen:

    docker run -p 5433:5432 -e POSTGRES_USER=docker -e POSTGRES_PASSWORD=docker -v /Users/Shared/postgres/data:/var/lib/postgresql/data postgres:10.6&
    docker ps        # um den Namen des Containers zu bekommen
    docker exec <container name> pg_dump docker >~/Documents/Backup/postgres/tt.sql
    
Ein Restore ist dann ebenso einfach indem man die .sql-Datei in psql piped (nachdem man den neuen Container gestartet hat)

    cat ~/Documents/Backup/postgres/tt.sql | docker exec -i <container name> psql -U docker
   


