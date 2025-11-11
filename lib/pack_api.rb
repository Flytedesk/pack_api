# frozen_string_literal: true
require "zeitwerk"
require "active_model"
require "active_record"
require "dry-types"
require "dry/struct"
require "brotli"

require_relative "types"
require_relative "pack_api/version"
require_relative "pack_api/config/dry_types_initializer"

loader = Zeitwerk::Loader.for_gem
loader.setup # ready!
