#!/usr/bin/env ruby
require 'pry'
require 'pry-nav'

class Cell
  attr_accessor :value, :group, :row, :col, :possible

  def initialize(value, row = nil, col=nil, group=nil)
    @value = value
    @possible = []
    @row = row
    @col = col
    @group = group
  end
end

RANGE = (1..9).to_a

class Row < Array

  def <<(value)
    raise StandardError, 'only Cell allowed as value' unless value.is_a? Cell
    super value
  end

  def []=(*attrs)
    raise StandardError, 'only Cell allowed as value' unless attrs.last.is_a? Cell
    super *attrs
  end

  def values
    self.map(&:value)
  end

  def unsolved_cells
    self.reject{|cell| cell.value > 0 }
  end

  def solved?
    @solved ||= possible.empty?
  end

  def allocated
    values.select{|r| r > 0 }
  end

  def possible
    (RANGE - allocated).sort
  end

end

class Col < Row; end
class Group < Row; end

class BasicSolver
  def self.solve(field)
    process(field.cells.reject{|r| r.value > 0 })
  end

  def self.process(acc = [])
    if acc.empty?
      acc
    else
      acc_ = []
      acc.each do |cell|
        possibilities = RANGE - (cell.group.values | cell.row.values | cell.col.values)
        if possibilities.count > 1
          cell.possible = possibilities
          acc_ << cell
        else
          cell.value = possibilities.first
        end
      end
      process(acc_ != acc ? acc_ : [])
    end
  end

end


class Field
  attr_reader :rows, :cols, :groups, :cells
  ROWS = 9

  def initialize(source)
    @rows = []
    @cols = []
    @groups = []
    @cells = []
    source =  File.open(source)
    (0..8).each do |i|
      line = source.readline
      @rows[i] ||= Row.new
      (0..8).each do |j|
        @cols[j] ||= Col.new
        gid = "#{i/3}#{j/3}".to_i(3)
        @groups[gid] ||= Group.new
        cell = Cell.new(line[j].to_i, @rows[i], @cols[j], @groups[gid])
        @rows[i] << cell
        @cols[j] << cell
        @groups[gid] << cell
        @cells << cell if cell.value == 0
      end
    end
  end

  def solve
    BasicSolver.solve(self)
  end

  def valid?
    self.rows.map(&:values).all?{|r| r.uniq.sort.eql? RANGE } &&
    self.cols.map(&:values).all?{|r| r.uniq.sort.eql? RANGE } &&
    self.groups.map(&:values).all?{|r| r.uniq.sort.eql? RANGE }
  end
end

t = Time.now
f = Field.new('source.txt')
f.solve

File.open('res.txt','w'){|file| file.write f.rows.map(&:values).map(&:join).join("\n")}
#f.rows.map(&:values).map(&:join).join("\n")
p Time.now - t



