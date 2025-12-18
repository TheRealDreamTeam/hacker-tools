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
      # Use full-text search only for suggestions (faster, better UX)
      # Semantic search is disabled for suggestions to improve responsiveness
      # Main search results still use semantic search for better accuracy
      @results = GlobalSearchService.search(
        query: @query,
        categories: @selected_categories,
        page_params: {},
        per_page: 5,
        use_semantic: false, # Disabled for suggestions - use full-text only for speed
        use_fulltext: true
      )
    end

    # Check if this is for navbar (navbar or mobile search suggestions) or homepage (both get sticky footer)
    is_navbar = params[:navbar] == "true"
    is_homepage = params[:homepage] == "true"

    render partial: "search/suggestions_panel",
           locals: { query: @query, results: @results, selected_categories: @selected_categories, is_navbar: is_navbar, is_homepage: is_homepage }
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

