CREATE TABLE pilots (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  commander_id INTEGER,
  rank_id INTEGER,

  FOREIGN KEY(rank_id) REFERENCES rank(id),
  FOREIGN KEY(commander_id) REFERENCES pilot(id)
);

CREATE TABLE ships (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  pilot_id INTEGER,

  FOREIGN KEY(pilot_id) REFERENCES pilot(id)
);

CREATE TABLE ranks (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

INSERT INTO
  ships (id, name, pilot_id)
VALUES
  (1, "Battlestar Galactica", 1),
  (2, "Viper X190", 3),
  (3, "Viper T191", 4),
  (4, "Viper T197", 5),
  (5, "Maron Transport", 2);

INSERT INTO
  pilots (id, name, rank_id, commander_id)
VALUES
  (1, "William Adama", 1, NULL),
  (2, "Saul Tigh", 2, 1),
  (3, "Kara 'Starbuck' Thrace", 3, 2),
  (4, "Ned Ruggeri", 4, 3),
  (5, "Lee Adama", 4, 3);

INSERT INTO
  ranks (id, name)
VALUES
  (1, "Commander"),
  (2, "Executive Officer"),
  (3, "Captain"),
  (4, "Lieutenant"),
  (5, "Janitor");
