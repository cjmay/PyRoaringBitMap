cdef class BitMap(AbstractBitMap):

    cdef compute_hash(self):
        '''Unsupported method.'''
        # For some reason, if we directly override __hash__ (either in BitMap or in FrozenBitMap), the __richcmp__
        # method disappears.
        raise TypeError('Cannot compute the hash of a %s.' % self.__class__.__name__)

    def add(self, uint32_t value):
        """
        Add an element to the bitmap. This has no effect if the element is already present.

        >>> bm = BitMap()
        >>> bm.add(42)
        >>> bm
        BitMap([42])
        >>> bm.add(42)
        >>> bm
        BitMap([42])
        """
        croaring.roaring_bitmap_add(self._c_bitmap, value)

    def update(self, *all_values): # FIXME could be more efficient
        """
        Add all the given values to the bitmap.

        >>> bm = BitMap([3, 12])
        >>> bm.update([8, 12, 55, 18])
        >>> bm
        BitMap([3, 8, 12, 18, 55])
        """
        cdef vector[uint32_t] buff_vect
        cdef unsigned[:] buff
        for values in all_values:
            if isinstance(values, AbstractBitMap):
                self |= values
            elif isinstance(values, range):
                self |= AbstractBitMap(values, copy_on_write=self.copy_on_write)
            elif isinstance(values, array.array) and len(values) > 0:
                buff = <array.array> values
                croaring.roaring_bitmap_add_many(self._c_bitmap, len(values), &buff[0])
            else:
                buff_vect = values
                croaring.roaring_bitmap_add_many(self._c_bitmap, len(values), &buff_vect[0])

    def discard(self, uint32_t value):
        """
        Remove an element from the bitmap. This has no effect if the element is not present.

        >>> bm = BitMap([3, 12])
        >>> bm.discard(3)
        >>> bm
        BitMap([12])
        >>> bm.discard(3)
        >>> bm
        BitMap([12])
        """
        croaring.roaring_bitmap_remove(self._c_bitmap, value)

    def remove(self, uint32_t value):
        """
        Remove an element from the bitmap. This raises a KeyError exception if the element does not exist in the bitmap.

        >>> bm = BitMap([3, 12])
        >>> bm.remove(3)
        >>> bm
        BitMap([12])
        >>> bm.remove(3)
        Traceback (most recent call last):
        ...
        KeyError: 3
        """
        if value in self:
            croaring.roaring_bitmap_remove(self._c_bitmap, value)
        else:
            raise KeyError(value)

    def intersection_update(self, *all_values): # FIXME could be more efficient
        """
        Update the bitmap by taking its intersection with the given values.

        >>> bm = BitMap([3, 12])
        >>> bm.intersection_update([8, 12, 55, 18])
        >>> bm
        BitMap([12])
        """
        cdef uint32_t elt
        for values in all_values:
            if isinstance(values, AbstractBitMap):
                self &= values
            else:
                self &= AbstractBitMap(values, copy_on_write=self.copy_on_write)

    def flip_inplace(self, uint64_t start, uint64_t end):
        """
        Compute (in place) the negation of the bitmap within the specified interval.

        Areas outside the range are passed unchanged.

        >>> bm = BitMap([3, 12])
        >>> bm.flip_inplace(10, 15)
        >>> bm
        BitMap([3, 10, 11, 13, 14])
        """
        croaring.roaring_bitmap_flip_inplace(self._c_bitmap, start, end)
