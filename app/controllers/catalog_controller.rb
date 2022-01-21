# frozen_string_literal: true

##
# Simplified catalog controller
class CatalogController < ApplicationController
  include Blacklight::Catalog

  configure_blacklight do |config|
          config.show.oembed_field = :oembed_url_ssm
          config.show.partials.insert(1, :oembed)

    config.view.gallery.document_component = Blacklight::Gallery::DocumentComponent
    # config.view.gallery.classes = 'row-cols-2 row-cols-md-3'
    config.view.masonry.document_component = Blacklight::Gallery::DocumentComponent
    config.view.slideshow.document_component = Blacklight::Gallery::SlideshowComponent
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: 'search',
      rows: 10,
      fl: '*'
    }

    config.document_solr_path = 'get'
    config.document_unique_id_param = 'ids'

    # solr field configuration for search results/index views
    config.index.title_field = 'title_ssi'

    config.add_search_field 'all_fields', label: I18n.t('spotlight.search.fields.search.all_fields')

    config.add_sort_field 'relevance', sort: 'score desc', label: I18n.t('spotlight.search.fields.sort.relevance')

    # FACETS
    # Special Projects / super_collection_name_ss

    # Contributing Organization / contributing_organization_name_s
    config.add_facet_field 'contributing_organization_ssi', :label => 'Contributing Organization', :limit => 8, collapse: false

    # Collection / collection_name_s
    config.add_facet_field 'collection_name_ssi', :label => 'Collection', :limit => 8, collapse: false

    # Type / types
    config.add_facet_field 'type_ssi', :label => 'Type', :limit => 8, collapse: false

    # Format / format_name
    config.add_facet_field 'physical_format_ssi', :label => 'Format', :limit => 8, collapse: false

    # Created / date_created_ss
    config.add_facet_field 'dat_ssi', :label => 'Created', :limit => 8, collapse: false

    # Subject / subject_ss
    config.add_facet_field 'formal_subject_ssim', :label => 'Subject', :limit => 8, collapse: false

    # Creator / creator_ss
    config.add_facet_field 'creator_ssim', :label => 'Creator', :limit => 8, collapse: false

    # Publisher / publisher_s
    config.add_facet_field 'publisher_ssi', :label => 'Publisher', :limit => 8, collapse: false

    # Contributor / contributor_ss
    config.add_facet_field 'contributor_ssim', :label => 'Contributor', :limit => 8, collapse: false

    # Language / language
    config.add_facet_field 'language_ssi', :label => 'Language', :limit => 8, collapse: false

  #SEARCH RESULTS FIELDS
    # Description
    config.add_index_field 'description_ts', :label => 'Description'
    # Creator
    config.add_index_field 'creator_ssim', :label => 'Creator'

    # Created
    config.add_index_field 'dat_ssi', :label => 'Created'

    # Contributed By
    config.add_index_field 'contributor_ssim', :label => 'Contributed By'

    # Last Updated
    config.add_index_field 'dmmodified_ssi', :label => 'Last Updated'

	#ITEM VIEW FIELDS
    # @TODO: itemprops
    # @TODO: Section Headers (##)

    # Title
      config.add_show_field 'title_ssi', label: 'Title', itemprop: 'title'
    # Description
      config.add_show_field 'description_ts', label: 'Description', itemprop: 'description'
    # Date Created
      config.add_show_field 'dat_ssi', label: 'Date Created', itemprop: 'date_created', link_to_facet: true
    # Historical Era - @TODO
      # config.add_show_field 'date_ssi', label: 'Historical Era', itemprop: 'historical_era'

    # Creator
      config.add_show_field 'creator_ssim', label: 'Creator', itemprop: 'creator', link_to_facet: true
    ## Physical Description
    # Item Type
      config.add_show_field 'type_ssi', label: 'Type', itemprop: 'type', link_to_facet: true
    # Format
      config.add_show_field 'physical_format_ssi', label: 'Format', itemprop: 'format', link_to_facet: true

    ## Topics
    # Subjects
      config.add_show_field 'formal_subject_ssim', label: 'Subject', itemprop: 'subject', link_to_facet: true
    # Language
      config.add_show_field 'language_ssi', label: 'Language', itemprop: 'language', link_to_facet: true

    ## Geographic Location
    # Country
      config.add_show_field 'country_ssi', label: 'Country', itemprop: 'country', link_to_facet: true
    # Continent - @TODO
    #  config.add_show_field 'language_ssi', label: 'Language', itemprop: 'language', link_to_facet: true

    ## Collection Information
    # Parent Collection
      config.add_show_field 'collection_name_ssi', label: 'Parent Collection', itemprop: 'parent_collection_name', link_to_facet: true
    # Contributing Organization
      config.add_show_field 'contributing_organization_ssi', label: 'Contributing Organization', itemprop: 'contributing_organization', link_to_facet: true
    # Contact Information
      config.add_show_field 'contact_information_ssi', label: 'Contact Information', itemprop: 'contact_information'
    # Fiscal Sponsor
      config.add_show_field 'fiscal_sponsor_ssi', label: 'Fiscal Sponsor', itemprop: 'fiscal_sponsor'

    ## Identifiers
    # DLS Identifier
      config.add_show_field 'local_identifier_ssi', label: 'DLS Identifier', itemprop: 'identifier'
    # Persistent URL - @TODO

    ## Can I Use It?
    # Copyright Statement...
    config.add_show_field 'rights_ssi', label: 'Copyright Statement', itemprop: 'copyright'

    ## Collection Well
    # Collection Description...

    config.add_facet_fields_to_solr_request!
    config.add_field_configuration_to_solr_request!
    # Set which views by default only have the title displayed, e.g.,
    # config.view.gallery.title_only_by_default = true
  end
end
