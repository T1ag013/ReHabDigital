-- =====================================================================
-- 1. Acesso: perfis e utilizadores
-- =====================================================================

CREATE TABLE perfil (
    perfil_id   NUMBER GENERATED ALWAYS AS IDENTITY,
    designacao  VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_perfil PRIMARY KEY (perfil_id),
    CONSTRAINT uq_perfil_designacao UNIQUE (designacao),
    CONSTRAINT ck_perfil_designacao CHECK (designacao IN
        ('PACIENTE', 'FISIOTERAPEUTA', 'MEDICO', 'TECNICO', 'ADMINISTRADOR'))
);

CREATE TABLE utilizador (
    utilizador_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    username       VARCHAR2(50)  NOT NULL,
    password_hash  VARCHAR2(255) NOT NULL,
    ativo          NUMBER(1) DEFAULT 1 NOT NULL,
    data_criacao   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    perfil_id      NUMBER NOT NULL,
    CONSTRAINT pk_utilizador PRIMARY KEY (utilizador_id),
    CONSTRAINT uq_utilizador_username UNIQUE (username),
    CONSTRAINT ck_utilizador_ativo CHECK (ativo IN (0, 1)),
    CONSTRAINT fk_utilizador_perfil FOREIGN KEY (perfil_id)
        REFERENCES perfil (perfil_id)
);

-- =====================================================================
-- 2. Pessoas
-- =====================================================================

CREATE TABLE codigo_postal (
    codigo_postal  VARCHAR2(8) NOT NULL,
    localidade     VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_codigo_postal PRIMARY KEY (codigo_postal),
    CONSTRAINT ck_codigo_postal_formato CHECK
        (REGEXP_LIKE(codigo_postal, '^[0-9]{4}-[0-9]{3}$'))
);

CREATE TABLE paciente (
    paciente_id      NUMBER GENERATED ALWAYS AS IDENTITY,
    codigo_interno   VARCHAR2(30)  NOT NULL,
    nome             VARCHAR2(150) NOT NULL,
    data_nascimento  DATE NOT NULL,
    sexo             VARCHAR2(20) NOT NULL,
    email            VARCHAR2(150) NOT NULL,
    telefone         VARCHAR2(30),
    rua              VARCHAR2(200),
    codigo_postal    VARCHAR2(8),
    data_registo     DATE DEFAULT SYSDATE NOT NULL,
    estado           VARCHAR2(20) DEFAULT 'ATIVO' NOT NULL,
    utilizador_id    NUMBER,
    CONSTRAINT pk_paciente PRIMARY KEY (paciente_id),
    CONSTRAINT uq_paciente_codigo_interno UNIQUE (codigo_interno),
    CONSTRAINT uq_paciente_utilizador UNIQUE (utilizador_id),
    CONSTRAINT ck_paciente_sexo CHECK (sexo IN ('FEMININO', 'MASCULINO', 'OUTRO')),
    CONSTRAINT ck_paciente_estado CHECK (estado IN ('ATIVO', 'INATIVO')),
    CONSTRAINT fk_paciente_codigo_postal FOREIGN KEY (codigo_postal)
        REFERENCES codigo_postal (codigo_postal),
    CONSTRAINT fk_paciente_utilizador FOREIGN KEY (utilizador_id)
        REFERENCES utilizador (utilizador_id)
);

CREATE TABLE profissional (
    profissional_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    nome             VARCHAR2(150) NOT NULL,
    profissao        VARCHAR2(30) NOT NULL,
    especializacao   VARCHAR2(100),
    email            VARCHAR2(150) NOT NULL,
    ativo            NUMBER(1) DEFAULT 1 NOT NULL,
    utilizador_id    NUMBER,
    CONSTRAINT pk_profissional PRIMARY KEY (profissional_id),
    CONSTRAINT uq_profissional_utilizador UNIQUE (utilizador_id),
    CONSTRAINT ck_profissional_profissao CHECK (profissao IN
        ('FISIOTERAPEUTA', 'MEDICO', 'TECNICO')),
    CONSTRAINT ck_profissional_ativo CHECK (ativo IN (0, 1)),
    CONSTRAINT fk_profissional_utilizador FOREIGN KEY (utilizador_id)
        REFERENCES utilizador (utilizador_id)
);

-- =====================================================================
-- 3. Terapêutica: programas, exercícios e equipamento
-- =====================================================================

CREATE TABLE programa (
    programa_id             NUMBER GENERATED ALWAYS AS IDENTITY,
    designacao              VARCHAR2(150) NOT NULL,
    objetivo_clinico        VARCHAR2(500) NOT NULL,
    area_intervencao        VARCHAR2(100) NOT NULL,
    duracao_semanas         NUMBER(3) NOT NULL,
    frequencia_recomendada  NUMBER(2) NOT NULL,          -- sessões por semana
    preco                   NUMBER(10,2) NOT NULL,
    ativo                   NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_programa PRIMARY KEY (programa_id),
    CONSTRAINT ck_programa_duracao CHECK (duracao_semanas > 0),
    CONSTRAINT ck_programa_frequencia CHECK (frequencia_recomendada > 0),
    CONSTRAINT ck_programa_preco CHECK (preco >= 0),
    CONSTRAINT ck_programa_ativo CHECK (ativo IN (0, 1))
);

CREATE TABLE exercicio (
    exercicio_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    designacao            VARCHAR2(150) NOT NULL,
    descricao             VARCHAR2(1000) NOT NULL,
    instrucoes            VARCHAR2(2000) NOT NULL,
    grupo_funcional       VARCHAR2(100) NOT NULL,
    dificuldade           VARCHAR2(20) NOT NULL,
    duracao_estimada_min  NUMBER(4) NOT NULL,
    preco                 NUMBER(10,2),                  -- preço de referência (opcional)
    ativo                 NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_exercicio PRIMARY KEY (exercicio_id),
    CONSTRAINT ck_exercicio_dificuldade CHECK (dificuldade IN
        ('FACIL', 'MEDIA', 'DIFICIL')),
    CONSTRAINT ck_exercicio_duracao CHECK (duracao_estimada_min > 0),
    CONSTRAINT ck_exercicio_preco CHECK (preco IS NULL OR preco >= 0),
    CONSTRAINT ck_exercicio_ativo CHECK (ativo IN (0, 1))
);

CREATE TABLE equipamento (
    equipamento_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    designacao      VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_equipamento PRIMARY KEY (equipamento_id),
    CONSTRAINT uq_equipamento_designacao UNIQUE (designacao)
);

CREATE TABLE exercicio_equipamento (
    exercicio_id    NUMBER NOT NULL,
    equipamento_id  NUMBER NOT NULL,
    CONSTRAINT pk_exercicio_equipamento PRIMARY KEY (exercicio_id, equipamento_id),
    CONSTRAINT fk_exercicio_equipamento_exercicio FOREIGN KEY (exercicio_id)
        REFERENCES exercicio (exercicio_id),
    CONSTRAINT fk_exercicio_equipamento_equipamento FOREIGN KEY (equipamento_id)
        REFERENCES equipamento (equipamento_id)
);

CREATE TABLE programa_exercicio (
    programa_id   NUMBER NOT NULL,
    exercicio_id  NUMBER NOT NULL,
    ordem         NUMBER(3) NOT NULL,
    repeticoes    NUMBER(4) NOT NULL,
    frequencia    NUMBER(2) NOT NULL,                    -- vezes por semana
    CONSTRAINT pk_programa_exercicio PRIMARY KEY (programa_id, exercicio_id),
    CONSTRAINT uq_programa_exercicio_ordem UNIQUE (programa_id, ordem),
    CONSTRAINT ck_programa_exercicio_ordem CHECK (ordem > 0),
    CONSTRAINT ck_programa_exercicio_repeticoes CHECK (repeticoes > 0),
    CONSTRAINT ck_programa_exercicio_frequencia CHECK (frequencia > 0),
    CONSTRAINT fk_programa_exercicio_programa FOREIGN KEY (programa_id)
        REFERENCES programa (programa_id),
    CONSTRAINT fk_programa_exercicio_exercicio FOREIGN KEY (exercicio_id)
        REFERENCES exercicio (exercicio_id)
);

-- =====================================================================
-- 4. Inscrições, sessões, notificações e execuções
-- =====================================================================

CREATE TABLE inscricao (
    inscricao_id     NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id      NUMBER NOT NULL,
    programa_id      NUMBER NOT NULL,
    profissional_id  NUMBER NOT NULL,                    -- profissional responsável
    data_inicio      DATE NOT NULL,
    data_fim         DATE,
    estado           VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_inscricao PRIMARY KEY (inscricao_id),
    CONSTRAINT uq_inscricao_paciente_programa_inicio
        UNIQUE (paciente_id, programa_id, data_inicio),
    CONSTRAINT ck_inscricao_estado CHECK (estado IN
        ('EM_CURSO', 'CONCLUIDA', 'SUSPENSA', 'CANCELADA')),
    CONSTRAINT ck_inscricao_data_fim CHECK (
        (estado IN ('EM_CURSO', 'SUSPENSA') AND data_fim IS NULL)
        OR (estado IN ('CONCLUIDA', 'CANCELADA') AND data_fim IS NOT NULL)),
    CONSTRAINT ck_inscricao_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT fk_inscricao_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id),
    CONSTRAINT fk_inscricao_programa FOREIGN KEY (programa_id)
        REFERENCES programa (programa_id),
    CONSTRAINT fk_inscricao_profissional FOREIGN KEY (profissional_id)
        REFERENCES profissional (profissional_id)
);

CREATE TABLE motivo_cancelamento (
    motivo_cancelamento_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    descricao               VARCHAR2(255) NOT NULL,
    CONSTRAINT pk_motivo_cancelamento PRIMARY KEY (motivo_cancelamento_id),
    CONSTRAINT uq_motivo_cancelamento_descricao UNIQUE (descricao)
);

CREATE TABLE sessao (
    sessao_id               NUMBER GENERATED ALWAYS AS IDENTITY,
    inscricao_id            NUMBER NOT NULL,
    profissional_id         NUMBER NOT NULL,
    motivo_cancelamento_id  NUMBER,
    data_hora               TIMESTAMP NOT NULL,
    duracao_min             NUMBER(4) NOT NULL,
    modalidade              VARCHAR2(20) NOT NULL,
    estado                  VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_sessao PRIMARY KEY (sessao_id),
    CONSTRAINT uq_sessao_inscricao_data_hora UNIQUE (inscricao_id, data_hora),
    CONSTRAINT ck_sessao_duracao CHECK (duracao_min > 0),
    CONSTRAINT ck_sessao_modalidade CHECK (modalidade IN ('PRESENCIAL', 'REMOTA')),
    CONSTRAINT ck_sessao_estado CHECK (estado IN
        ('AGENDADA', 'REALIZADA', 'CANCELADA_PACIENTE',
         'CANCELADA_PROFISSIONAL', 'NAO_REALIZADA')),
    CONSTRAINT ck_sessao_motivo CHECK (
        (estado IN ('CANCELADA_PACIENTE', 'CANCELADA_PROFISSIONAL')
            AND motivo_cancelamento_id IS NOT NULL)
        OR (estado NOT IN ('CANCELADA_PACIENTE', 'CANCELADA_PROFISSIONAL')
            AND motivo_cancelamento_id IS NULL)),
    CONSTRAINT fk_sessao_inscricao FOREIGN KEY (inscricao_id)
        REFERENCES inscricao (inscricao_id),
    CONSTRAINT fk_sessao_profissional FOREIGN KEY (profissional_id)
        REFERENCES profissional (profissional_id),
    CONSTRAINT fk_sessao_motivo_cancelamento FOREIGN KEY (motivo_cancelamento_id)
        REFERENCES motivo_cancelamento (motivo_cancelamento_id)
);

CREATE TABLE notificacao (
    notificacao_id      NUMBER GENERATED ALWAYS AS IDENTITY,
    sessao_id           NUMBER NOT NULL,
    tipo                VARCHAR2(20) NOT NULL,
    data_envio          TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    email_destinatario  VARCHAR2(150) NOT NULL,          -- cópia do endereço usado no envio
    estado              VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_notificacao PRIMARY KEY (notificacao_id),
    CONSTRAINT uq_notificacao_sessao_envio UNIQUE (sessao_id, data_envio),
    CONSTRAINT ck_notificacao_tipo CHECK (tipo IN ('MARCACAO', 'ATUALIZACAO')),
    CONSTRAINT ck_notificacao_estado CHECK (estado IN
        ('PENDENTE', 'ENVIADA', 'FALHADA')),
    CONSTRAINT fk_notificacao_sessao FOREIGN KEY (sessao_id)
        REFERENCES sessao (sessao_id)
);

CREATE TABLE execucao_exercicio (
    execucao_exercicio_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    sessao_id              NUMBER NOT NULL,
    exercicio_id           NUMBER NOT NULL,
    repeticoes_realizadas  NUMBER(4) NOT NULL,
    duracao_min            NUMBER(4),
    observacoes            VARCHAR2(1000),
    CONSTRAINT pk_execucao_exercicio PRIMARY KEY (execucao_exercicio_id),
    CONSTRAINT ck_execucao_exercicio_repeticoes CHECK (repeticoes_realizadas >= 0),
    CONSTRAINT ck_execucao_exercicio_duracao CHECK (duracao_min IS NULL OR duracao_min > 0),
    CONSTRAINT fk_execucao_exercicio_sessao FOREIGN KEY (sessao_id)
        REFERENCES sessao (sessao_id),
    CONSTRAINT fk_execucao_exercicio_exercicio FOREIGN KEY (exercicio_id)
        REFERENCES exercicio (exercicio_id)
);

-- =====================================================================
-- 5. Monitorização: dispositivos, medições, limites e alertas
-- =====================================================================

CREATE TABLE dispositivo (
    dispositivo_id    NUMBER GENERATED ALWAYS AS IDENTITY,
    numero_serie      VARCHAR2(100) NOT NULL,
    modelo            VARCHAR2(100) NOT NULL,
    tipo_dispositivo  VARCHAR2(30) NOT NULL,
    ativo             NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_dispositivo PRIMARY KEY (dispositivo_id),
    CONSTRAINT uq_dispositivo_numero_serie UNIQUE (numero_serie),
    CONSTRAINT ck_dispositivo_tipo CHECK (tipo_dispositivo IN
        ('OXIMETRO', 'MONITOR_CARDIACO', 'PEDOMETRO', 'SENSOR_MOVIMENTO')),
    CONSTRAINT ck_dispositivo_ativo CHECK (ativo IN (0, 1))
);

CREATE TABLE atribuicao_dispositivo (
    atribuicao_dispositivo_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id                NUMBER NOT NULL,
    dispositivo_id             NUMBER NOT NULL,
    data_inicio                DATE NOT NULL,
    data_fim                   DATE,
    CONSTRAINT pk_atribuicao_dispositivo PRIMARY KEY (atribuicao_dispositivo_id),
    CONSTRAINT uq_atribuicao_dispositivo_inicio
        UNIQUE (paciente_id, dispositivo_id, data_inicio),
    CONSTRAINT ck_atribuicao_dispositivo_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT fk_atribuicao_dispositivo_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id),
    CONSTRAINT fk_atribuicao_dispositivo_dispositivo FOREIGN KEY (dispositivo_id)
        REFERENCES dispositivo (dispositivo_id)
);

CREATE TABLE tipo_indicador (
    tipo_indicador_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    designacao         VARCHAR2(100) NOT NULL,
    unidade            VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_tipo_indicador PRIMARY KEY (tipo_indicador_id),
    CONSTRAINT uq_tipo_indicador_designacao UNIQUE (designacao)
);

-- A severidade ordena-se alfabeticamente como AVISO < CRITICO. Se forem
-- acrescentados níveis, deve passar a existir um nível numérico.
CREATE TABLE limite_referencia (
    limite_referencia_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    tipo_indicador_id     NUMBER NOT NULL,
    valor_min             NUMBER(10,2),
    valor_max             NUMBER(10,2),
    severidade            VARCHAR2(20) NOT NULL,
    valido_desde          DATE NOT NULL,
    CONSTRAINT pk_limite_referencia PRIMARY KEY (limite_referencia_id),
    CONSTRAINT uq_limite_referencia_indicador
        UNIQUE (tipo_indicador_id, severidade, valido_desde),
    CONSTRAINT ck_limite_referencia_severidade CHECK (severidade IN ('AVISO', 'CRITICO')),
    CONSTRAINT ck_limite_referencia_valores CHECK (
        (valor_min IS NOT NULL OR valor_max IS NOT NULL)
        AND (valor_min IS NULL OR valor_max IS NULL OR valor_min <= valor_max)),
    CONSTRAINT fk_limite_referencia_tipo_indicador FOREIGN KEY (tipo_indicador_id)
        REFERENCES tipo_indicador (tipo_indicador_id)
);

CREATE TABLE medicao (
    medicao_id         NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id        NUMBER NOT NULL,
    dispositivo_id     NUMBER NOT NULL,
    tipo_indicador_id  NUMBER NOT NULL,
    data_hora          TIMESTAMP NOT NULL,
    valor              NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_medicao PRIMARY KEY (medicao_id),
    CONSTRAINT uq_medicao_instante
        UNIQUE (paciente_id, dispositivo_id, data_hora, tipo_indicador_id),
    CONSTRAINT fk_medicao_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id),
    CONSTRAINT fk_medicao_dispositivo FOREIGN KEY (dispositivo_id)
        REFERENCES dispositivo (dispositivo_id),
    CONSTRAINT fk_medicao_tipo_indicador FOREIGN KEY (tipo_indicador_id)
        REFERENCES tipo_indicador (tipo_indicador_id)
);

CREATE TABLE alerta (
    alerta_id             NUMBER GENERATED ALWAYS AS IDENTITY,
    medicao_id            NUMBER NOT NULL,
    limite_referencia_id  NUMBER NOT NULL,
    profissional_id       NUMBER,                        -- só preenchido quando tratado
    data_hora             TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    estado                VARCHAR2(20) DEFAULT 'ABERTO' NOT NULL,
    data_tratamento       TIMESTAMP,
    nota_resolucao        VARCHAR2(1000),
    CONSTRAINT pk_alerta PRIMARY KEY (alerta_id),
    CONSTRAINT uq_alerta_medicao UNIQUE (medicao_id),
    CONSTRAINT ck_alerta_estado CHECK (estado IN ('ABERTO', 'TRATADO')),
    CONSTRAINT ck_alerta_tratamento CHECK (
        (estado = 'ABERTO' AND profissional_id IS NULL AND data_tratamento IS NULL)
        OR (estado = 'TRATADO' AND profissional_id IS NOT NULL AND data_tratamento IS NOT NULL)),
    CONSTRAINT ck_alerta_datas CHECK (data_tratamento IS NULL OR data_tratamento >= data_hora),
    CONSTRAINT fk_alerta_medicao FOREIGN KEY (medicao_id)
        REFERENCES medicao (medicao_id),
    CONSTRAINT fk_alerta_limite_referencia FOREIGN KEY (limite_referencia_id)
        REFERENCES limite_referencia (limite_referencia_id),
    CONSTRAINT fk_alerta_profissional FOREIGN KEY (profissional_id)
        REFERENCES profissional (profissional_id)
);

-- =====================================================================
-- 6. Informação clínica (Anexo I)
-- =====================================================================

CREATE TABLE condicao (
    condicao_id              NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id              NUMBER NOT NULL,
    diagnostico              VARCHAR2(200) NOT NULL,
    area_reabilitacao        VARCHAR2(100) NOT NULL,
    nivel_funcional_inicial  VARCHAR2(100) NOT NULL,
    data_registo             DATE NOT NULL,
    CONSTRAINT pk_condicao PRIMARY KEY (condicao_id),
    CONSTRAINT uq_condicao_diagnostico UNIQUE (paciente_id, diagnostico, data_registo),
    CONSTRAINT fk_condicao_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id)
);

CREATE TABLE limitacao_funcional (
    limitacao_funcional_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    condicao_id             NUMBER NOT NULL,
    descricao               VARCHAR2(300) NOT NULL,
    CONSTRAINT pk_limitacao_funcional PRIMARY KEY (limitacao_funcional_id),
    CONSTRAINT uq_limitacao_funcional_descricao UNIQUE (condicao_id, descricao),
    CONSTRAINT fk_limitacao_funcional_condicao FOREIGN KEY (condicao_id)
        REFERENCES condicao (condicao_id)
);

CREATE TABLE objetivo (
    objetivo_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id        NUMBER NOT NULL,
    tipo_indicador_id  NUMBER,                           -- só nas metas mensuráveis
    descricao          VARCHAR2(500) NOT NULL,
    valor_alvo         NUMBER(10,2),
    prazo              DATE NOT NULL,
    estado             VARCHAR2(20) DEFAULT 'EM_CURSO' NOT NULL,
    CONSTRAINT pk_objetivo PRIMARY KEY (objetivo_id),
    CONSTRAINT ck_objetivo_estado CHECK (estado IN
        ('EM_CURSO', 'ATINGIDO', 'NAO_ATINGIDO')),
    CONSTRAINT ck_objetivo_meta CHECK (valor_alvo IS NULL OR tipo_indicador_id IS NOT NULL),
    CONSTRAINT fk_objetivo_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id),
    CONSTRAINT fk_objetivo_tipo_indicador FOREIGN KEY (tipo_indicador_id)
        REFERENCES tipo_indicador (tipo_indicador_id)
);

CREATE TABLE avaliacao_inicial (
    avaliacao_inicial_id  NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id           NUMBER NOT NULL,
    tipo_indicador_id     NUMBER NOT NULL,
    profissional_id       NUMBER NOT NULL,
    data_avaliacao        DATE NOT NULL,
    valor                 NUMBER(10,2) NOT NULL,
    observacoes           VARCHAR2(1000),
    CONSTRAINT pk_avaliacao_inicial PRIMARY KEY (avaliacao_inicial_id),
    CONSTRAINT uq_avaliacao_inicial_indicador
        UNIQUE (paciente_id, data_avaliacao, tipo_indicador_id),
    CONSTRAINT fk_avaliacao_inicial_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id),
    CONSTRAINT fk_avaliacao_inicial_tipo_indicador FOREIGN KEY (tipo_indicador_id)
        REFERENCES tipo_indicador (tipo_indicador_id),
    CONSTRAINT fk_avaliacao_inicial_profissional FOREIGN KEY (profissional_id)
        REFERENCES profissional (profissional_id)
);

CREATE TABLE consentimento (
    consentimento_id    NUMBER GENERATED ALWAYS AS IDENTITY,
    paciente_id         NUMBER NOT NULL,
    tipo_consentimento  VARCHAR2(30) NOT NULL,
    data_concessao      DATE NOT NULL,
    data_revogacao      DATE,
    CONSTRAINT pk_consentimento PRIMARY KEY (consentimento_id),
    CONSTRAINT uq_consentimento_concessao
        UNIQUE (paciente_id, tipo_consentimento, data_concessao),
    CONSTRAINT ck_consentimento_tipo CHECK (tipo_consentimento IN
        ('TRATAMENTO_DADOS', 'MONITORIZACAO_REMOTA', 'PARTILHA_DADOS')),
    CONSTRAINT ck_consentimento_datas CHECK
        (data_revogacao IS NULL OR data_revogacao >= data_concessao),
    CONSTRAINT fk_consentimento_paciente FOREIGN KEY (paciente_id)
        REFERENCES paciente (paciente_id)
);

-- =====================================================================
-- 7. Índices únicos condicionais (regras de negócio)
-- =====================================================================

-- Um paciente não tem duas inscrições em curso ou suspensas no mesmo programa.
CREATE UNIQUE INDEX uq_inscricao_aberta ON inscricao (
    CASE WHEN estado IN ('EM_CURSO', 'SUSPENSA') THEN paciente_id END,
    CASE WHEN estado IN ('EM_CURSO', 'SUSPENSA') THEN programa_id END
);

-- Cada dispositivo tem, no máximo, uma atribuição ativa (sem data de fim).
CREATE UNIQUE INDEX uq_atribuicao_dispositivo_ativa ON atribuicao_dispositivo (
    CASE WHEN data_fim IS NULL THEN dispositivo_id END
);

-- =====================================================================
-- 8. Índices de apoio às chaves estrangeiras
--    O Oracle não cria índices para chaves estrangeiras. Só se criam onde
--    a coluna não é o início de uma chave primária ou de um UNIQUE.
-- =====================================================================

CREATE INDEX ix_utilizador_perfil ON utilizador (perfil_id);
CREATE INDEX ix_paciente_codigo_postal ON paciente (codigo_postal);
CREATE INDEX ix_exercicio_equipamento_equipamento ON exercicio_equipamento (equipamento_id);
CREATE INDEX ix_programa_exercicio_exercicio ON programa_exercicio (exercicio_id);
CREATE INDEX ix_inscricao_programa ON inscricao (programa_id);
CREATE INDEX ix_inscricao_profissional ON inscricao (profissional_id);
CREATE INDEX ix_sessao_profissional ON sessao (profissional_id);
CREATE INDEX ix_sessao_motivo_cancelamento ON sessao (motivo_cancelamento_id);
CREATE INDEX ix_execucao_exercicio_sessao ON execucao_exercicio (sessao_id);
CREATE INDEX ix_execucao_exercicio_exercicio ON execucao_exercicio (exercicio_id);
CREATE INDEX ix_atribuicao_dispositivo_dispositivo ON atribuicao_dispositivo (dispositivo_id);
CREATE INDEX ix_medicao_dispositivo ON medicao (dispositivo_id);
CREATE INDEX ix_medicao_tipo_indicador ON medicao (tipo_indicador_id);
CREATE INDEX ix_alerta_limite_referencia ON alerta (limite_referencia_id);
CREATE INDEX ix_alerta_profissional ON alerta (profissional_id);
CREATE INDEX ix_objetivo_paciente ON objetivo (paciente_id);
CREATE INDEX ix_objetivo_tipo_indicador ON objetivo (tipo_indicador_id);
CREATE INDEX ix_avaliacao_inicial_tipo_indicador ON avaliacao_inicial (tipo_indicador_id);
CREATE INDEX ix_avaliacao_inicial_profissional ON avaliacao_inicial (profissional_id);

-- Índices de apoio às consultas (sessões futuras e medições recentes)
CREATE INDEX ix_sessao_data_hora ON sessao (data_hora);
CREATE INDEX ix_medicao_data_hora ON medicao (data_hora);
