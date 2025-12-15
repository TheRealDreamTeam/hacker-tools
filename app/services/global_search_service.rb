class GlobalSearchService
  DEFAULT_PER_PAGE = 10
  BUFFER_MULTIPLIER = 10
  MAX_BUFFER = 200
  CATEGORIES = %i[tools submissions tags users lists].freeze

  Result = Struct.new(:items, :total_count, :page, :per_page, keyword_init: true) do
    def has_more?
      total_count.to_i > page.to_i * per_page.to_i
    end
  end

  def self.search(query:, categories:, page_params:, per_page: DEFAULT_PER_PAGE, use_semantic: true, use_fulltext: true)
    new(
      query: query,
      categories: categories,
      page_params: page_params,
      per_page: per_page,
      use_semantic: use_semantic,
      use_fulltext: use_fulltext
    ).search
  end

  def initialize(query:, categories:, page_params:, per_page:, use_semantic:, use_fulltext:)
    @query = query.to_s.strip
    @selected_categories = (categories & CATEGORIES).presence || CATEGORIES
    @per_page = per_page.presence || DEFAULT_PER_PAGE
    @page_params = page_params || {}
    @use_semantic = use_semantic
    @use_fulltext = use_fulltext
  end

  def search
    return empty_results if @query.blank?

    results = {}

    @selected_categories.each do |category|
      results[category] = send("search_#{category}")
    end

    results
  rescue StandardError => e
    Rails.logger.error("Global search error: #{e.message}")
    empty_results
  end

  private

  def search_tools
    buffer_limit = buffered_limit
    combined_results = UnifiedSearchService.search(
      @query,
      limit: buffer_limit,
      use_semantic: @use_semantic,
      use_fulltext: @use_fulltext
    )[:tools]

    paginate_array(combined_results, :tools)
  rescue StandardError => e
    Rails.logger.error("Tool search error: #{e.message}")
    Result.new(items: [], total_count: 0, page: current_page(:tools), per_page: @per_page)
  end

  def search_submissions
    buffer_limit = buffered_limit
    combined_results = SubmissionSearchService.search(
      @query,
      limit: buffer_limit,
      status: :completed,
      use_semantic: @use_semantic,
      use_fulltext: @use_fulltext
    )

    ActiveRecord::Associations::Preloader.new.preload(combined_results, [:tags, :tools, :user])
    paginate_array(combined_results, :submissions)
  rescue StandardError => e
    Rails.logger.error("Submission search error: #{e.message}")
    Result.new(items: [], total_count: 0, page: current_page(:submissions), per_page: @per_page)
  end

  def search_tags
    scope = Tag.where("tag_name ILIKE ?", "%#{@query}%")
               .order(Arel.sql("CASE WHEN tag_name ILIKE #{ActiveRecord::Base.connection.quote(prefix_query)} THEN 0 ELSE 1 END"))
               .order(created_at: :desc)

    total = scope.count
    items = scope.offset(offset_for(:tags)).limit(@per_page)

    Result.new(items:, total_count: total, page: current_page(:tags), per_page: @per_page)
  rescue StandardError => e
    Rails.logger.error("Tag search error: #{e.message}")
    Result.new(items: [], total_count: 0, page: current_page(:tags), per_page: @per_page)
  end

  def search_users
    scope = User.active
                .where("username ILIKE :q OR user_bio ILIKE :q", q: "%#{@query}%")
                .order(Arel.sql("CASE WHEN username ILIKE #{ActiveRecord::Base.connection.quote(prefix_query)} THEN 0 ELSE 1 END"))
                .order(created_at: :desc)

    total = scope.count
    items = scope.offset(offset_for(:users)).limit(@per_page)

    Result.new(items:, total_count: total, page: current_page(:users), per_page: @per_page)
  rescue StandardError => e
    Rails.logger.error("User search error: #{e.message}")
    Result.new(items: [], total_count: 0, page: current_page(:users), per_page: @per_page)
  end

  def search_lists
    scope = List.public_lists
                .joins(:user)
                .where("list_name ILIKE :q OR users.username ILIKE :q", q: "%#{@query}%")
                .order(Arel.sql("CASE WHEN list_name ILIKE #{ActiveRecord::Base.connection.quote(prefix_query)} THEN 0 ELSE 1 END"))
                .order(created_at: :desc)
                .includes(:user, :tools)

    total = scope.count
    items = scope.offset(offset_for(:lists)).limit(@per_page)

    Result.new(items:, total_count: total, page: current_page(:lists), per_page: @per_page)
  rescue StandardError => e
    Rails.logger.error("List search error: #{e.message}")
    Result.new(items: [], total_count: 0, page: current_page(:lists), per_page: @per_page)
  end

  def paginate_array(results, category)
    array = results || []
    total = array.length
    items = array.slice(offset_for(category), @per_page) || []

    Result.new(items:, total_count: total, page: current_page(category), per_page: @per_page)
  end

  def buffered_limit
    [@per_page.to_i * BUFFER_MULTIPLIER, MAX_BUFFER].min
  end

  def current_page(category)
    ( @page_params["#{category}_page".to_sym].presence || 1 ).to_i.clamp(1, 10_000)
  end

  def offset_for(category)
    (current_page(category) - 1) * @per_page.to_i
  end

  def prefix_query
    "#{@query}%"
  end

  def empty_results
    CATEGORIES.index_with do |category|
      Result.new(items: [], total_count: 0, page: current_page(category), per_page: @per_page)
    end
  end
end

