CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE projects (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    project_name VARCHAR(1024) NOT NULL
);

CREATE TABLE project_strings (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    string VARCHAR(2048) NOT NULL,
    project_id UUID NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    UNIQUE (project_id, string)
);

CREATE TABLE locales (
    PRIMARY KEY (code),
    code VARCHAR(5) NOT NULL,
    lang VARCHAR(512) NOT NULL,
    country VARCHAR(512) NOT NULL
);

CREATE TABLE project_translations (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    translation TEXT,
    locale_code VARCHAR(5) NOT NULL REFERENCES locales (code),
    project_id UUID NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    string_id UUID NOT NULL REFERENCES project_strings (id) ON DELETE CASCADE,
    UNIQUE (project_id, string_id, locale_code)
);

CREATE TABLE users (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    user_name VARCHAR(2048) NOT NULL,
    email VARCHAR(2048) NOT NULL,
    hashed_password VARCHAR(4096) NOT NULL,
    UNIQUE (email)
);

CREATE TABLE roles (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    role_code VARCHAR(255) NOT NULL,
    UNIQUE (role_code)
);

CREATE TABLE project_users (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users (id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles (id) ON DELETE CASCADE,
    UNIQUE (project_id, user_id)
);

CREATE TABLE project_clients (
    PRIMARY KEY (id),
    id UUID DEFAULT uuid_generate_v4(),
    client_name VARCHAR(2048) NOT NULL,
    client_secret VARCHAR(4096) NOT NULL,
    project_id UUID REFERENCES projects (id) ON DELETE CASCADE
);