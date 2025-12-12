\restrict PLyGWoppCm5fN83fHAkM774oDtvquh3xcGTQtCK5bQNagu5eBOBnbqdSka0AOFL

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comment_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_upvotes (
    id bigint NOT NULL,
    comment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comment_upvotes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comment_upvotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_upvotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comment_upvotes_id_seq OWNED BY public.comment_upvotes.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    commentable_type character varying NOT NULL,
    commentable_id bigint NOT NULL,
    comment text NOT NULL,
    comment_type integer DEFAULT 0 NOT NULL,
    visibility integer DEFAULT 0 NOT NULL,
    parent_id bigint,
    solved boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    followable_type character varying NOT NULL,
    followable_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follows_id_seq OWNED BY public.follows.id;


--
-- Name: list_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.list_submissions (
    id bigint NOT NULL,
    list_id bigint NOT NULL,
    submission_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: list_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.list_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.list_submissions_id_seq OWNED BY public.list_submissions.id;


--
-- Name: list_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.list_tools (
    id bigint NOT NULL,
    list_id bigint NOT NULL,
    tool_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: list_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.list_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.list_tools_id_seq OWNED BY public.list_tools.id;


--
-- Name: lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lists (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    list_name character varying NOT NULL,
    list_type integer DEFAULT 0 NOT NULL,
    visibility integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lists_id_seq OWNED BY public.lists.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: submission_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_tags (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: submission_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_tags_id_seq OWNED BY public.submission_tags.id;


--
-- Name: submission_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_tools (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    tool_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: submission_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_tools_id_seq OWNED BY public.submission_tools.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    submission_type integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    submission_url character varying,
    normalized_url character varying,
    author_note text,
    submission_name character varying,
    submission_description text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    duplicate_of_id bigint,
    processed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    tag_name character varying NOT NULL,
    tag_description text,
    tag_type integer DEFAULT 0 NOT NULL,
    parent_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tool_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_tags (
    id bigint NOT NULL,
    tool_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tool_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tool_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tool_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tool_tags_id_seq OWNED BY public.tool_tags.id;


--
-- Name: tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tools (
    id bigint NOT NULL,
    tool_name character varying NOT NULL,
    tool_description text,
    tool_url character varying,
    author_note text,
    visibility integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tools_id_seq OWNED BY public.tools.id;


--
-- Name: user_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_submissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    submission_id bigint NOT NULL,
    read_at timestamp(6) without time zone,
    upvote boolean DEFAULT false NOT NULL,
    favorite boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_submissions_id_seq OWNED BY public.user_submissions.id;


--
-- Name: user_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tools (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tool_id bigint NOT NULL,
    read_at timestamp(6) without time zone,
    upvote boolean DEFAULT false NOT NULL,
    favorite boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_tools_id_seq OWNED BY public.user_tools.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    username character varying NOT NULL,
    user_type integer DEFAULT 0 NOT NULL,
    user_status integer DEFAULT 0 NOT NULL,
    user_bio text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: comment_upvotes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_upvotes ALTER COLUMN id SET DEFAULT nextval('public.comment_upvotes_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows ALTER COLUMN id SET DEFAULT nextval('public.follows_id_seq'::regclass);


--
-- Name: list_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_submissions ALTER COLUMN id SET DEFAULT nextval('public.list_submissions_id_seq'::regclass);


--
-- Name: list_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_tools ALTER COLUMN id SET DEFAULT nextval('public.list_tools_id_seq'::regclass);


--
-- Name: lists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists ALTER COLUMN id SET DEFAULT nextval('public.lists_id_seq'::regclass);


--
-- Name: submission_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tags ALTER COLUMN id SET DEFAULT nextval('public.submission_tags_id_seq'::regclass);


--
-- Name: submission_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tools ALTER COLUMN id SET DEFAULT nextval('public.submission_tools_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tool_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_tags ALTER COLUMN id SET DEFAULT nextval('public.tool_tags_id_seq'::regclass);


--
-- Name: tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tools ALTER COLUMN id SET DEFAULT nextval('public.tools_id_seq'::regclass);


--
-- Name: user_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions ALTER COLUMN id SET DEFAULT nextval('public.user_submissions_id_seq'::regclass);


--
-- Name: user_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tools ALTER COLUMN id SET DEFAULT nextval('public.user_tools_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: comment_upvotes comment_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_upvotes
    ADD CONSTRAINT comment_upvotes_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (id);


--
-- Name: list_submissions list_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_submissions
    ADD CONSTRAINT list_submissions_pkey PRIMARY KEY (id);


--
-- Name: list_tools list_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_tools
    ADD CONSTRAINT list_tools_pkey PRIMARY KEY (id);


--
-- Name: lists lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT lists_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: submission_tags submission_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tags
    ADD CONSTRAINT submission_tags_pkey PRIMARY KEY (id);


--
-- Name: submission_tools submission_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tools
    ADD CONSTRAINT submission_tools_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tool_tags tool_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_tags
    ADD CONSTRAINT tool_tags_pkey PRIMARY KEY (id);


--
-- Name: tools tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_pkey PRIMARY KEY (id);


--
-- Name: user_submissions user_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions
    ADD CONSTRAINT user_submissions_pkey PRIMARY KEY (id);


--
-- Name: user_tools user_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tools
    ADD CONSTRAINT user_tools_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_on_blob_id_variation_digest_f36bede0d9; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_blob_id_variation_digest_f36bede0d9 ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_comment_upvotes_on_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_upvotes_on_comment_id ON public.comment_upvotes USING btree (comment_id);


--
-- Name: index_comment_upvotes_on_comment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_comment_upvotes_on_comment_id_and_user_id ON public.comment_upvotes USING btree (comment_id, user_id);


--
-- Name: index_comment_upvotes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_upvotes_on_user_id ON public.comment_upvotes USING btree (user_id);


--
-- Name: index_comments_on_commentable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable ON public.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_parent_id ON public.comments USING btree (parent_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_follows_on_followable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_followable ON public.follows USING btree (followable_type, followable_id);


--
-- Name: index_follows_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_user_id ON public.follows USING btree (user_id);


--
-- Name: index_follows_on_user_id_and_followable_type_and_followable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follows_on_user_id_and_followable_type_and_followable_id ON public.follows USING btree (user_id, followable_type, followable_id);


--
-- Name: index_list_submissions_on_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_submissions_on_list_id ON public.list_submissions USING btree (list_id);


--
-- Name: index_list_submissions_on_list_id_and_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_list_submissions_on_list_id_and_submission_id ON public.list_submissions USING btree (list_id, submission_id);


--
-- Name: index_list_submissions_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_submissions_on_submission_id ON public.list_submissions USING btree (submission_id);


--
-- Name: index_list_tools_on_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_tools_on_list_id ON public.list_tools USING btree (list_id);


--
-- Name: index_list_tools_on_list_id_and_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_list_tools_on_list_id_and_tool_id ON public.list_tools USING btree (list_id, tool_id);


--
-- Name: index_list_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_tools_on_tool_id ON public.list_tools USING btree (tool_id);


--
-- Name: index_lists_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lists_on_user_id ON public.lists USING btree (user_id);


--
-- Name: index_submission_tags_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_tags_on_submission_id ON public.submission_tags USING btree (submission_id);


--
-- Name: index_submission_tags_on_submission_id_and_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submission_tags_on_submission_id_and_tag_id ON public.submission_tags USING btree (submission_id, tag_id);


--
-- Name: index_submission_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_tags_on_tag_id ON public.submission_tags USING btree (tag_id);


--
-- Name: index_submission_tools_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_tools_on_submission_id ON public.submission_tools USING btree (submission_id);


--
-- Name: index_submission_tools_on_submission_id_and_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submission_tools_on_submission_id_and_tool_id ON public.submission_tools USING btree (submission_id, tool_id);


--
-- Name: index_submission_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_tools_on_tool_id ON public.submission_tools USING btree (tool_id);


--
-- Name: index_submissions_on_duplicate_of_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_duplicate_of_id ON public.submissions USING btree (duplicate_of_id);


--
-- Name: index_submissions_on_embedding_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_embedding_vector ON public.submissions USING ivfflat (embedding public.vector_cosine_ops) WITH (lists='1');


--
-- Name: index_submissions_on_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_metadata ON public.submissions USING gin (metadata);


--
-- Name: index_submissions_on_normalized_url_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submissions_on_normalized_url_and_user_id ON public.submissions USING btree (normalized_url, user_id) WHERE (normalized_url IS NOT NULL);


--
-- Name: index_submissions_on_processed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_processed_at ON public.submissions USING btree (processed_at);


--
-- Name: index_submissions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_status ON public.submissions USING btree (status);


--
-- Name: index_submissions_on_status_and_submission_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_status_and_submission_type ON public.submissions USING btree (status, submission_type);


--
-- Name: index_submissions_on_submission_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_submission_type ON public.submissions USING btree (submission_type);


--
-- Name: index_submissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_user_id ON public.submissions USING btree (user_id);


--
-- Name: index_submissions_on_user_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_user_id_and_status ON public.submissions USING btree (user_id, status);


--
-- Name: index_tags_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_parent_id ON public.tags USING btree (parent_id);


--
-- Name: index_tags_on_tag_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_tag_name ON public.tags USING btree (tag_name);


--
-- Name: index_tool_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tool_tags_on_tag_id ON public.tool_tags USING btree (tag_id);


--
-- Name: index_tool_tags_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tool_tags_on_tool_id ON public.tool_tags USING btree (tool_id);


--
-- Name: index_tool_tags_on_tool_id_and_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tool_tags_on_tool_id_and_tag_id ON public.tool_tags USING btree (tool_id, tag_id);


--
-- Name: index_tools_on_embedding_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tools_on_embedding_vector ON public.tools USING ivfflat (embedding public.vector_cosine_ops) WITH (lists='1');


--
-- Name: index_tools_on_tool_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tools_on_tool_name ON public.tools USING btree (tool_name);


--
-- Name: index_user_submissions_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_submissions_on_submission_id ON public.user_submissions USING btree (submission_id);


--
-- Name: index_user_submissions_on_submission_id_and_upvote; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_submissions_on_submission_id_and_upvote ON public.user_submissions USING btree (submission_id, upvote) WHERE (upvote = true);


--
-- Name: index_user_submissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_submissions_on_user_id ON public.user_submissions USING btree (user_id);


--
-- Name: index_user_submissions_on_user_id_and_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_submissions_on_user_id_and_submission_id ON public.user_submissions USING btree (user_id, submission_id);


--
-- Name: index_user_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_tools_on_tool_id ON public.user_tools USING btree (tool_id);


--
-- Name: index_user_tools_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_tools_on_user_id ON public.user_tools USING btree (user_id);


--
-- Name: index_user_tools_on_user_id_and_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_tools_on_user_id_and_tool_id ON public.user_tools USING btree (user_id, tool_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_tools fk_rails_0530f769c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tools
    ADD CONSTRAINT fk_rails_0530f769c9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: comment_upvotes fk_rails_1c6419547a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_upvotes
    ADD CONSTRAINT fk_rails_1c6419547a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_tools fk_rails_297494f3d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tools
    ADD CONSTRAINT fk_rails_297494f3d0 FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: comments fk_rails_31554e7034; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_31554e7034 FOREIGN KEY (parent_id) REFERENCES public.comments(id);


--
-- Name: follows fk_rails_32479bd030; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_rails_32479bd030 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submissions fk_rails_3581963034; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_3581963034 FOREIGN KEY (duplicate_of_id) REFERENCES public.submissions(id);


--
-- Name: tool_tags fk_rails_3717b45175; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_tags
    ADD CONSTRAINT fk_rails_3717b45175 FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: list_tools fk_rails_4356fa6b18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_tools
    ADD CONSTRAINT fk_rails_4356fa6b18 FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: list_submissions fk_rails_6f6db7812e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_submissions
    ADD CONSTRAINT fk_rails_6f6db7812e FOREIGN KEY (list_id) REFERENCES public.lists(id);


--
-- Name: submissions fk_rails_8d85741475; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_8d85741475 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submission_tags fk_rails_ae9baf1153; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tags
    ADD CONSTRAINT fk_rails_ae9baf1153 FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: tags fk_rails_aff1790b59; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_rails_aff1790b59 FOREIGN KEY (parent_id) REFERENCES public.tags(id);


--
-- Name: list_tools fk_rails_b40b78c26e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_tools
    ADD CONSTRAINT fk_rails_b40b78c26e FOREIGN KEY (list_id) REFERENCES public.lists(id);


--
-- Name: submission_tags fk_rails_ba36863c09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tags
    ADD CONSTRAINT fk_rails_ba36863c09 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: comment_upvotes fk_rails_cedf3d8f5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_upvotes
    ADD CONSTRAINT fk_rails_cedf3d8f5b FOREIGN KEY (comment_id) REFERENCES public.comments(id);


--
-- Name: list_submissions fk_rails_cf329920d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_submissions
    ADD CONSTRAINT fk_rails_cf329920d0 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: tool_tags fk_rails_d31f911899; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_tags
    ADD CONSTRAINT fk_rails_d31f911899 FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: lists fk_rails_d6cf4279f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_rails_d6cf4279f7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submission_tools fk_rails_e987d13b7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tools
    ADD CONSTRAINT fk_rails_e987d13b7b FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: user_submissions fk_rails_f8e1a3b846; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions
    ADD CONSTRAINT fk_rails_f8e1a3b846 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submission_tools fk_rails_fa54f497aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_tools
    ADD CONSTRAINT fk_rails_fa54f497aa FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: user_submissions fk_rails_fbe75b9b27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_submissions
    ADD CONSTRAINT fk_rails_fbe75b9b27 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- PostgreSQL database dump complete
--

\unrestrict PLyGWoppCm5fN83fHAkM774oDtvquh3xcGTQtCK5bQNagu5eBOBnbqdSka0AOFL

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251212130222');

