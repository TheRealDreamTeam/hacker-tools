class SearchController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @query = params[:query].to_s.strip
    @all_categories = GlobalSearchService::CATEGORIES
    @selected_categories = extract_categories
    @per_page = (params[:per_page].presence&.to_i || GlobalSearchService::DEFAULT_PER_PAGE).clamp(1, 50)
    @page_params = page_params

    @results = if @query.present?
                 GlobalSearchService.search(
                   query: @query,
                   categories: @selected_categories,
                   page_params: @page_params,
                   per_page: @per_page,
                   use_semantic: true,
                   use_fulltext: true
                 )
               else
                 GlobalSearchService::CATEGORIES.index_with do |category|
                   GlobalSearchService::Result.new(items: [], total_count: 0, page: page_params["#{category}_page".to_sym] || 1, per_page: @per_page)
                 end
               end
  end

  def suggestions
    @query = params[:query].to_s.strip
    @all_categories = GlobalSearchService::CATEGORIES
    @selected_categories = extract_categories

    if @query.length < 3
      @results = GlobalSearchService::CATEGORIES.index_with do |category|
        GlobalSearchService::Result.new(items: [], total_count: 0, page: 1, per_page: 5)
      end
    else
      # Enable semantic search for suggestions to handle typos (e.g., "htwire" -> "Hotwire")
      # Use both semantic and full-text search for better suggestions
      @results = GlobalSearchService.search(
        query: @query,
        categories: @selected_categories,
        page_params: {},
        per_page: 5,
        use_semantic: true, # Enable semantic search for suggestions
        use_fulltext: true
      )
    end

    render partial: "search/suggestions_panel",
           locals: { query: @query, results: @results, selected_categories: @selected_categories }
  end

  private

  def extract_categories
    selected = params[:categories]&.map(&:to_sym)&.uniq
    return GlobalSearchService::CATEGORIES if selected.blank?

    selected & GlobalSearchService::CATEGORIES
  end

  def page_params
    {
      tools_page: params[:tools_page],
      submissions_page: params[:submissions_page],
      tags_page: params[:tags_page],
      users_page: params[:users_page],
      lists_page: params[:lists_page]
    }
  end
end

